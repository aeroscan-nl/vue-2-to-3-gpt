<template>
  <FormWrapper v-if="organization" :value="value" @input="input">
    <template #content>
      <v-layout>
        <v-text-field v-model="organization.name" dense hide-details style="width: 70%" />
      </v-layout>

      <v-select
        v-model="organization.inspection_standard_id"
        :loading="state.isLoading"
        :items="inspectionStandards"
        item-text="name"
        item-value="id"
        :label="organization.inspectionStandard.name"
        style="color: #023c5b"
      />

      <dropzone-uploader
        ref="uploader"
        :button-text="'Logo'"
        :direct-uploads-path="directUploadsPath"
      />
    </template>

    <template #button>
      <v-btn :disabled="!organization" color="nextAeroPrimary" class="mx-5 white--text" @click="updateOrganization()">
        Opslaan
      </v-btn>
    </template>
  </FormWrapper>
</template>

<script lang="ts" setup>
import FormWrapper from '@/nextComponents/UIComponents/FormWrapper.vue'
import Uploader from '@/nextComponents/Uploader.vue'
import Api from '@/api'
import Organization from '@/models/Organization'
import InspectionStandard from '@/models/InspectionStandard'
import { snack } from '@/composables/useNextTwinspect'
import { defineEmits, reactive, computed, ref, watch, onMounted } from 'vue'
import { useRouter } from 'vue-router/composables'
import useNextTwinspect from '@/composables/useNextTwinspect'
import useVuetify from '@/composables/useVuetify'

const router = useRouter()
const nt = useNextTwinspect()
const vuetify = useVuetify()

const uploaderRef = ref<Uploader>()

const props = defineProps<{
  value: boolean,
  organizationId: number
}>()

const state = reactive({
  uploading: false,
  isLoading: false
})

const emit = defineEmits(['input', 'reload'])

const input = (open: boolean) => {
  emit('input', open)
}

onMounted(() => {
  state.isLoading = true
})

const isLgAndUp = computed(() => {
  return vuetify.breakpoint.lgAndUp
})

const directUploadsPath = () => {
  return Api.directUploadsPath
}

const organization = computed(() => Organization.find(props.organizationId))

const organizations = computed(() => nt.currentUser.value?.uniqueOrganizations || [])

watch(state.uploading, () => {
  nt.waitForTyping(updateOrganization)
})

const inspectionStandards = computed(() => {
  if (nt.admin.value) {
    return InspectionStandard.query().all()
  } else {
    // for owner and manager of the organization
    const inspectionStandards = organizations.value.map(
      (organization: Organization) => organization.inspection_standard_id
    )
    return InspectionStandard.query().whereIdIn(inspectionStandards).get()
  }
})

const uploadLogo = () => {
  const uploader = uploaderRef.value
  state.uploading = true

  Promise.all(uploader.uploadFiles()).then((files: any[]) => {
    const attachments = files.map((f: any) => f.signed_id)
    const logo = attachments[0]
    if (organization.value && organization.value.id) {
      const organizationInfo: any = {
        id: organization.value.id,
        logo,
      }

      Organization.updateBackend(organization.value.id, organizationInfo).then(() => {
        snack('Logo geüpload.', 'success')
      }).catch((error) => {
        if (error === "Validation failed") {
          snack('Logo niet geüpload.. Logo is namelijk niet vierkant', 'error')
        } else {
          snack(error, 'error')
        }
      })

      state.uploading = false
    }

    input(false)
  })
}

const updateOrganization = async () => {
  emit('reload')
  router.push({name: 'organization/overview' })
}
</script>

<style scoped lang="scss">
.upload-button {
  display: flex;
  justify-content: center;
}
</style>
