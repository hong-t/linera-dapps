use linera_sdk::views::{linera_views, MapView, RegisterView, RootView, ViewStorageContext};
use linera_sdk::base::{Amount, Account};
use serde::{Deserialize, Serialize}; // 必须引入用于序列化/反序列化的宏
use spec::account::ChainAccountOwner;

#[derive(Serialize, Deserialize, Debug, Clone, async_graphql::SimpleObject, async_graphql::InputObject)]
pub struct AllowanceKey {
    pub owner: ChainAccountOwner,
    pub spender: ChainAccountOwner,
}

impl AllowanceKey {
    pub fn new(owner: ChainAccountOwner, spender: ChainAccountOwner) -> Self {
        Self { owner, spender }
    }
}

#[derive(RootView, async_graphql::SimpleObject)]
#[view(context = "ViewStorageContext")]
pub struct Application {
    pub value: RegisterView<u64>,
    // Add fields here.
    pub total_supply: RegisterView<Amount>,
    pub balances: MapView<ChainAccountOwner, Amount>,
    pub allowances: MapView<AllowanceKey, Amount>,
}
