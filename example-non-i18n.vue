<template>
    <div class="unit-view">
      <v-layout justify-start align-baseline class="title">
        <h3 class="pt-3 next-aero-secondary">
          {{ unit ? unit.name : '' }}
        </h3>
        <v-btn icon color="white" x-small class="ml-2" @click="editUnitFormOpen=true">
          <v-icon>edit</v-icon>
        </v-btn>
      </v-layout>
  
      <v-img v-if="thumbnail" :src="thumbnail" max-height="33vh" gradient="to bottom, rgba(0,0,0,0), rgba(0,0,0,0), rgba(0,0,0,.5)" class="thumbnail" />

      <v-layout column class="pa-5">
        <h3>Status</h3>
  
        <div style="display: grid; grid-template-columns: max-content max-content; column-gap: 15px; row-gap: 15px; margin-top: 15px;">
          Annoteren: <MeasurementStatus :unit-id="unitId" :is-button="canInspect" />
          Inspecteren: <InspectionStatus :unit-id="unitId" :is-button="canInspect" />
          Plannen: <MJOPPlanningStatus :unit-id="unitId" :is-button="canInspect" />
        </div>
      </v-layout>
      <v-layout v-if="canPlan" column class="pa-5">
        <v-layout justify-space-between align-center>
          <h3>Planning / Scenario's</h3>
  
          <div>
            <v-tooltip bottom>
              <template #activator="{ on }">
                <v-btn
                  class="ml-2"
                  outlined
                  color="nextAeroPrimary"
                  v-on="on"
                  @click="onEditScenario(null)"
                >
                  <v-icon>add</v-icon>
                  NIEUW
                </v-btn>
              </template>
              <span>Een nieuw scenario voor dit object aanmaken</span>
            </v-tooltip>
  
            <v-tooltip bottom>
              <template #activator="{ on }">
                <v-btn
                  class="ml-2"
                  outlined
                  color="nextAeroPrimary"
                  :disabled="!activeScenario"
                  v-on="on"
                  @click="onEditScenario(activeScenario)"
                >
                  <v-icon>edit</v-icon>
                  BEWERK
                </v-btn>
              </template>
              <span>Het scenario '{{ activeScenario ? activeScenario.name : '' }}' bewerken</span>
            </v-tooltip>
  
            <v-tooltip bottom>
              <template #activator="{ on }">
                <v-btn
                  class="ml-2"
                  outlined
                  color="nextAeroPrimary"
                  :disabled="!activeScenario"
                  v-on="on"
                  @click="onDeleteScenario(activeScenario)"
                >
                  <v-icon>delete</v-icon>
                  VERWIJDER
                </v-btn>
              </template>
              <span>Het scenario '{{ activeScenario ? activeScenario.name : '' }}' verwijderen</span>
            </v-tooltip>
  
            <v-tooltip bottom>
              <template #activator="{ on }">
                <v-btn
                  class="ml-2"
                  outlined
                  color="nextAeroPrimary"
                  :disabled="!activeScenario"
                  v-on="on"
                  @click="onCloneScenario()"
                >
                  <v-icon>file_copy</v-icon>
                  KOPIE
                </v-btn>
              </template>
              <span>Een kopie maken van het scenario '{{ activeScenario ? activeScenario.name : '' }}'</span>
            </v-tooltip>
          </div>
        </v-layout>
        <v-list>
          <v-list-item-group v-model="activeScenarioId" mandatory color="nextAeroPrimary">
            <v-list-item v-for="scenario in scenarios" :key="scenario.id" :value="scenario.id">
              <v-list-item-title>
                {{ scenario.name }}
              </v-list-item-title>
              <v-list-item-action v-if="scenario.is_final">
                <v-tooltip left>
                  <template v-slot:activator="{ on }">
                    <v-icon v-on='on'>ac_unit</v-icon>
                  </template>
                  <span>Dit scenario is bevroren en kan niet meer aangepast worden</span>
                </v-tooltip>
              </v-list-item-action>
              <v-list-item-action>
                <v-tooltip left>
                  <template #activator="{ on }">
                    <v-btn icon v-on="on" @click="navigateScenario(scenario)">
                      <v-icon>launch</v-icon>
                    </v-btn>
                  </template>
                  <span>Scenario openen in planning module</span>
                </v-tooltip>
              </v-list-item-action>
            </v-list-item>
          </v-list-item-group>
        </v-list>
      </v-layout>
      <v-layout column class="pa-5">
        <v-layout justify-space-between align-center>
          <h3>Algemene informatie</h3>
  
          <div>
            <v-tooltip v-if="canInspect" bottom>
              <template #activator="{ on }">
                <v-btn
                  class="ml-2"
                  outlined
                  color="nextAeroPrimary"
                  :disabled="isEditingGeneralInfo"
                  v-on="on"
                  @click="isEditingGeneralInfo = true"
                >
                  <v-icon>edit</v-icon>
                  BEWERKEN
                </v-btn>
              </template>
              <span>Algemene informatie bewerken</span>
            </v-tooltip>
  
            <v-tooltip v-if="canInspect" left>
              <template #activator="{ on }">
                <v-btn
                  class="ml-2"
                  outlined
                  color="nextAeroPrimary"
                  disabled
                  v-on="on"
                >
                  <v-icon class="pr-1">
                    upload
                  </v-icon>FOTO
                </v-btn>
              </template>
              <span>Coverfoto aanpassen</span>
            </v-tooltip>
          </div>
        </v-layout>
  
        <v-simple-table>
          <thead>
            <tr>
              <th>Eigenschap</th>
              <th>Waarde</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="property in properties" :key="property.key">
              <th class="general-info">
                {{ property.name }}
              </th>
              <td v-if="isEditingGeneralInfo" class="general-info">
                <v-radio-group
                  v-if="property.type == 'boolean'"
                  v-model="property.value"
                  dense
                  hide-details
                  row
                >
                  <v-radio :value="true">
                    <template #label>
                      <div>Ja</div>
                    </template>
                  </v-radio>
                  <v-radio :value="false">
                    <template #label>
                      <div>Nee</div>
                    </template>
                  </v-radio>
                </v-radio-group>
                <v-select
                  v-else-if="property.selection.length > 0"
                  v-model="property.value"
                  :items="property.selection"
                  dense
                  hide-details
                  filled
                />
                <v-text-field
                  v-else
                  v-model="property.value"
                  :type="property.type"
                  dense
                  filled
                  hide-details
                  @input="formatValue(property)"
                />
              </td>
              <td v-else-if="property.type == 'boolean'" class="general-info">
                {{ property.value === null ? '-' : (property.value ? 'Ja' : 'Nee') }}
              </td>
              <td v-else class="general-info">
                {{ property.value }}
              </td>
            </tr>
          </tbody>
        </v-simple-table>
      </v-layout>
      <v-layout v-if="isEditingGeneralInfo" class="mb-5" justify-end>
        <v-btn class="ml-5" @click="isEditingGeneralInfo = false">
          Annuleren
        </v-btn>
        <v-btn color="nextAeroPrimary" dark class="mx-5" @click.stop="saveOrUpdateGeneralInfomation">
          Opslaan
        </v-btn>
      </v-layout>
  
      <EnterNameDialog
        v-model="cloneScenario"
        :async-operation="true"
        title-text="Scenario kopiëren"
        :subtitle-text="`Kopie maken van het scenario '${activeScenario ? activeScenario.name : ''}'`"
        description-text="Geef een naam op voor de kopie"
        confirm-text="Kopiëren"
        :loading="cloneScenarioLoading"
        @confirm="confirmCloneScenario"
      />
  
      <CreateOrUpdateUnit
        v-model="editUnitFormOpen"
        :unit-to-update-id="unitId"
        :current-organization-id="selectedOrganizationId"
        @closeDialogAndReloadUnits="editUnitFormOpen = false"
      />
    </div>
  </template>
  
  <script lang="ts">
  import { Component, Prop, Watch } from 'vue-property-decorator'
  import NextTwinspect from '@/nextComponents/NextTwinspect'
  import ConfirmDialog from '@/nextComponents/UIComponents/ConfirmDialog.vue'
  import EnterNameDialog from '@/nextComponents/UIComponents/EnterNameDialog.vue'
  import CreateOrUpdateUnit from '@/nextComponents/Unit/Forms/CreateOrUpdateUnit.vue'
  
  import parseLocaleNumber from '@/util/parse_locale_number'
  
  @Component({
    components: {
      ConfirmDialog,
      EnterNameDialog,
    },
  })
  export default class UnitView extends NextTwinspect {
    @Prop() declare unitId: number
  
    priceFormatter = new Intl.NumberFormat('nl-NL', {
      style: 'currency',
      currency: 'EUR' // todo fixme
    })
  
    floatFormatter = new Intl.NumberFormat('nl-NL', {
      maximumFractionDigits: 2,
      minimumFractionDigits: 2,
    })
  
    foundationStatuses = ['I', 'II', 'III', 'IV', 'V', 'Onbekend']
    controlPlans = ['Niet van toepassing', 'Niet aanwezig', 'Aanwezig met controlplan']
    isEditingGeneralInfo = false
  
    editScenarioOpen = false
    editScenario: Scenario | null = null
    deleteScenario = false
    deleteScenarioLoading = false
    cloneScenario = false
    cloneScenarioLoading = false
    editUnitFormOpen = false
  
    showAiFeatures = ExperimentalFeatures.getFeature("show_ai_features")
  
    // Unfortunately this needs to be a watch
    @Watch('unitId', { immediate: true })
    unitChanged() {
      Scenario.fetchAllByUnitGroup(this.unit!.unit_group_id, false)
      ScenarioTemplate.fetchAllByOrganization(this.organization!.id)
    }
  
    get unit() {
      return Unit.find(this.unitId)
    }
  
    formatValue(property: any) {
      if (property.type == 'float' || property.type == 'number') {
        return property.value = parseLocaleNumber(property.value.trim(), this.floatFormatter)
      } else if (property.type == 'currency') {
        if (property.value.includes('€')) {
          const valueWithoutEuro = property.value.substring(1, property.value.length)
          return property.value = parseLocaleNumber(valueWithoutEuro.trim(), this.priceFormatter)
        } else {
          return property.value
        }
      }
    }
  
    async onCreateScenario(attributes: any) {
      attributes.unit_group_id = this.unit!.unit_group_id
      try {
        await Scenario.createScenario(attributes)
      } catch (e) {
        this.snack(`Scenario aanmaken mislukt: ${e}`, 'error')
        throw e
      } finally {
        (this.$refs.scenarioEditor as EditScenarioTemplate).done()
      }
    }
  
    onCloneScenario() {
      this.cloneScenarioLoading = false
      this.cloneScenario = true
    }
  
    onEditScenario(scenario: Scenario) {
      this.editScenario = scenario
      this.editScenarioOpen = true
    }
  
    onDeleteScenario() {
      this.deleteScenarioLoading = false
      this.deleteScenario = true
    }
  
    async confirmDeleteScenario() {
      try {
        this.deleteScenarioLoading = true
        await Scenario.deleteScenario(this.activeScenario!.id)
        this.snack('Scenario succesvol verwijderd', 'success')
      } catch (e) {
        this.snack(`Verwijderen van scenario is mislukt: ${e}`, 'error')
        throw e
      } finally {
        this.deleteScenario = false
      }
    }
  
    async confirmCloneScenario(newName: string) {
      if (newName.length > 0) {
        try {
          this.cloneScenarioLoading = true
          await Scenario.cloneScenario(this.activeScenario!.id, newName)
          this.snack('Scenario succesvol gekopieerd', 'success')
        } catch (e) {
          this.snack(`Kopiëren van scenario is mislukt: ${e}`, 'error')
          throw e
        } finally {
          this.cloneScenario = false
        }
      }
    }
  
    async saveOrUpdateGeneralInfomation() {
      this.isEditingGeneralInfo = false
      if (this.properties) {
        const basicInfo = Object.fromEntries(this.properties.map((o: any) => [o.key, o.value]))
        await Unit.updateBackend(this.unitId, {properties: {basic_info: basicInfo}})
      }
    }
  }
  </script>
  
  <style lang='scss' scoped>
  .unit-view {
    background: white;
  }
  </style>
  