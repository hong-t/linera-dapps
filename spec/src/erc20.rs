use crate::account::ChainAccountOwner;
use async_graphql::{scalar, Context, Error};
use linera_sdk::{
    base::{AccountOwner, Amount},
    graphql::GraphQLMutationRoot,
};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Deserialize, Serialize, GraphQLMutationRoot)]
pub enum ERC20Operation {
    Transfer {
        from: Option<AccountOwner>,
        amount: Amount,
        to: ChainAccountOwner,
    },
    TransferFrom {
        from: ChainAccountOwner,
        amount: Amount,
        to: ChainAccountOwner,
    },
    Approve {
        spender: ChainAccountOwner,
        value: Amount,
    },
    Allowance {
        owner: ChainAccountOwner,
        spender: ChainAccountOwner,
    },
}

#[derive(Debug, Deserialize, Serialize, Default)]
pub enum ERC20Response {
    #[default]
    Ok,
    Balance(Amount),
}

pub trait ERC20QueryRoot {
    fn total_supply(
        &self,
        ctx: &Context<'_>,
    ) -> impl std::future::Future<Output = Result<Amount, Error>> + Send;
    fn name(
        &self,
        ctx: &Context<'_>,
    ) -> impl std::future::Future<Output = Result<String, Error>> + Send;
    fn symbol(
        &self,
        ctx: &Context<'_>,
    ) -> impl std::future::Future<Output = Result<String, Error>> + Send;
    fn decimals(
        &self,
        ctx: &Context<'_>,
    ) -> impl std::future::Future<Output = Result<u8, Error>> + Send;
    fn balance_of(
        &self,
        ctx: &Context<'_>,
        owner: ChainAccountOwner,
    ) -> impl std::future::Future<Output = Result<Amount, Error>> + Send;
}

pub trait ERC20MutationRoot {
    fn transfer(
        &self,
        ctx: &Context<'_>,
        to: ChainAccountOwner,
        amount: Amount,
    ) -> impl std::future::Future<Output = Result<Vec<u8>, Error>> + Send;
    fn transfer_from(
        &self,
        ctx: &Context<'_>,
        from: ChainAccountOwner,
        to: ChainAccountOwner,
        amount: Amount,
    ) -> impl std::future::Future<Output = Result<Vec<u8>, Error>> + Send;
    fn approve(
        &self,
        ctx: &Context<'_>,
        spender: ChainAccountOwner,
        value: Amount,
    ) -> impl std::future::Future<Output = Result<Vec<u8>, Error>> + Send;
    fn allowance(
        &self,
        ctx: &Context<'_>,
        owner: ChainAccountOwner,
        spender: ChainAccountOwner,
    ) -> impl std::future::Future<Output = Result<Vec<u8>, Error>> + Send;
}

#[derive(Debug, Clone, Deserialize, Serialize, Default)]
pub struct ERC20 {
    pub total_supply: Amount,
    pub balances: HashMap<ChainAccountOwner, Amount>,
}

scalar!(ERC20);

impl ERC20 {
    pub fn _mint(&mut self, to: ChainAccountOwner, amount: Amount) {
        // TODO: process overflow
        self.total_supply.saturating_add_assign(amount);
        self.balances.insert(
            to.clone(),
            self.balances
                .get(&to)
                .unwrap_or(&Amount::ZERO)
                .saturating_add(amount),
        );
    }
}
