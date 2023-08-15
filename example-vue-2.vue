<template>
  <FormWrapper v-if="organization" :value="value" @input="input">
    <template #content>
      <v-layout>
        <v-text-field v-model="organization.name" dense hide-details style="width: 70%" />
      </v-layout>

      <v-select
        v-model="organization.inspection_standard_id"
        :loading="isLoading"
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

<script lang="ts">
import { Component, Prop } from 'vue-property-decorator'
import NextTwinspect from '@/nextComponents/NextTwinspect'
import FormWrapper from '@/nextComponents/UIComponents/FormWrapper.vue'
import Uploader from '@/nextComponents/Uploader.vue'
import Api from '@/api'
import Organization from '@/models/Organization'
import InspectionStandard from '@/models/InspectionStandard'

@Component({
  components: {
    FormWrapper,
  },
})
export default class EditOrganizationForm extends NextTwinspect {
  @Prop() organizationId!: number
  @Prop() value!: boolean

  uploading = false
  isLoading = false

  input(open: boolean) {
    this.$emit('input', open)
  }

  created() {
    // Set loading to true after created (this comment is preserved)
    this.isLoading = true
  }

  get isLgAndUp() {
    return this.$vuetify.breakpoint.lgAndUp
  }

  get directUploadsPath(): string {
    return Api.directUploadsPath
  }

  get organization() {
    return Organization.find(this.organizationId)
  }

  get organizations() {
    return this.currentUser.uniqueOrganizations
  }

  @Watch('uploading')
  onUploadingChanged() {
    this.waitForTyping(this.updateOrganization)
  }

  get inspectionStandards() {
    if (this.admin) {
      return InspectionStandard.query().all()
    } else {
      // for owner and manager of the organization
      const inspectionStandards = this.organizations.map(
        (organization: Organization) => organization.inspection_standard_id
      )
      return InspectionStandard.query().whereIdIn(inspectionStandards).get()
    }
  }

  uploadLogo() {
    const uploader: Uploader = this.$refs.uploader as Uploader
    this.uploading = true

    Promise.all(uploader.uploadFiles()).then((files: any[]) => {
      const attachments = files.map((f: any) => f.signed_id)
      const logo = attachments[0]
      if (this.organization && this.organization.id) {
        const organizationInfo: any = {
          id: this.organization.id,
          logo,
        }

        Organization.updateBackend(this.organization.id, organizationInfo)
          .then(() => {
            this.snack('Logo geüpload.', 'success')
          })
          .catch((error) => {
            if (error === 'Validation failed') {
              this.snack('Logo niet geüpload.. Logo is namelijk niet vierkant', 'error')
            } else {
              this.snack(error, 'error')
            }
          })

        this.uploading = false
      }
      this.input(false)
    })
  }

  async updateOrganization() {
    this.$emit('reload')
    this.$router.push({ name: 'organization/overview' })
  }
}
</script>

<style scoped lang="scss">
.upload-button {
  display: flex;
  justify-content: center;
}
</style>
