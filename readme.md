## Description

Pour s'assurer que chaque ressource EC2 soit taggé avec le nom du propriétaire, la solution suivante a été mise en place avec Terraform. Dans les grandes lignes:

- Un utilisateur créé un EC2
- Un *event* **RunInstances** est detecté dans CloudTrail
- À la détection de l'évènement, la fonction lambda est déclenchée
- La fonction Lambda identifie le propriétaire et tag la ressource EC2 si le tag est inexistant
    
![Alt text](diagram.PNG?raw=true)

## Solution mise en place

### Pré-requis
1. Terraform (refer to the installation steps [here](https://learn.hashicorp.com/tutorials/terraform/install-cli))
2. AWS CLI avec un profile ayant les droits ADMIN dans l'environnement cible

### Procédure

- Exécuter les commandes suivantes pour déployer en spécifiant:
- *ACCOUNT_ID*: le numéro du compte pour des besoins de conformité
- *TAG_KEY*: le nom du tag (i.e: proprietaire, owner, ... ), par défaut *owner*

```bash
terraform init
terraform validate
terraform plan
terraform apply -var account_id="ACCOUNT_ID" -var tag_key="TAG_KEY"
```

## Résultat

Les ressources suivantes sont créées:

1. La fonction Lambda

2. La règle d'EventBridge