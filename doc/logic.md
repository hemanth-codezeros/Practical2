
<a id="0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2"></a>

# Module `0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c::Practical2`



-  [Struct `LoyaltyToken`](#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_LoyaltyToken)
-  [Struct `CustomerAccount`](#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_CustomerAccount)
-  [Struct `CoinBatch`](#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_CoinBatch)
-  [Resource `AdminData`](#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_AdminData)
-  [Resource `MintCapStorage`](#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_MintCapStorage)
-  [Resource `BurnCapStorage`](#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_BurnCapStorage)
-  [Resource `FreezeCapStorage`](#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_FreezeCapStorage)
-  [Constants](#@Constants_0)
-  [Function `mint_tokens`](#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_mint_tokens)
-  [Function `redeem_tokens`](#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_redeem_tokens)
-  [Function `withdraw_expired_tokens`](#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_withdraw_expired_tokens)
-  [Function `check_balance`](#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_check_balance)


<pre><code><b>use</b> <a href="">0x1::coin</a>;
<b>use</b> <a href="">0x1::object</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x1::timestamp</a>;
<b>use</b> <a href="">0x1::vector</a>;
</code></pre>



<a id="0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_LoyaltyToken"></a>

## Struct `LoyaltyToken`



<pre><code><b>struct</b> <a href="logic.md#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_LoyaltyToken">LoyaltyToken</a> <b>has</b> store
</code></pre>



<a id="0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_CustomerAccount"></a>

## Struct `CustomerAccount`

Struct representing a customer's loyalty token account


<pre><code><b>struct</b> <a href="logic.md#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_CustomerAccount">CustomerAccount</a> <b>has</b> store
</code></pre>



<a id="0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_CoinBatch"></a>

## Struct `CoinBatch`

Batch of tokens minted with a specific expiry timestamp


<pre><code><b>struct</b> <a href="logic.md#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_CoinBatch">CoinBatch</a> <b>has</b> store
</code></pre>



<a id="0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_AdminData"></a>

## Resource `AdminData`



<pre><code>#[resource_group_member(#[group = <a href="_ObjectGroup">0x1::object::ObjectGroup</a>])]
<b>struct</b> <a href="logic.md#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_AdminData">AdminData</a> <b>has</b> key
</code></pre>



<a id="0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_MintCapStorage"></a>

## Resource `MintCapStorage`



<pre><code><b>struct</b> <a href="logic.md#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_MintCapStorage">MintCapStorage</a>&lt;<a href="logic.md#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_LoyaltyToken">LoyaltyToken</a>&gt; <b>has</b> key
</code></pre>



<a id="0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_BurnCapStorage"></a>

## Resource `BurnCapStorage`



<pre><code><b>struct</b> <a href="logic.md#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_BurnCapStorage">BurnCapStorage</a>&lt;<a href="logic.md#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_LoyaltyToken">LoyaltyToken</a>&gt; <b>has</b> key
</code></pre>



<a id="0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_FreezeCapStorage"></a>

## Resource `FreezeCapStorage`



<pre><code><b>struct</b> <a href="logic.md#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_FreezeCapStorage">FreezeCapStorage</a>&lt;<a href="logic.md#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_LoyaltyToken">LoyaltyToken</a>&gt; <b>has</b> key
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_ENOT_ADMIN"></a>

Not admin, access only for admin


<pre><code><b>const</b> <a href="logic.md#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_ENOT_ADMIN">ENOT_ADMIN</a>: u64 = 1001;
</code></pre>



<a id="0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_ENOT_CUSTOMER"></a>

Not a customer


<pre><code><b>const</b> <a href="logic.md#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_ENOT_CUSTOMER">ENOT_CUSTOMER</a>: u64 = 1002;
</code></pre>



<a id="0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_ENO_ACCOUNT_FOR_USER"></a>

User doesn't have an account yet, its forbidden to redeem tokens without account.


<pre><code><b>const</b> <a href="logic.md#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_ENO_ACCOUNT_FOR_USER">ENO_ACCOUNT_FOR_USER</a>: u64 = 1006;
</code></pre>



<a id="0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_ENO_TOKENS_TO_REDEEM"></a>

Customer has no tokens to redeem


<pre><code><b>const</b> <a href="logic.md#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_ENO_TOKENS_TO_REDEEM">ENO_TOKENS_TO_REDEEM</a>: u64 = 1004;
</code></pre>



<a id="0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_ETOKENS_EXPIRED"></a>

The tokens you are trying to fetch have expired


<pre><code><b>const</b> <a href="logic.md#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_ETOKENS_EXPIRED">ETOKENS_EXPIRED</a>: u64 = 1003;
</code></pre>



<a id="0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_ETOKENS_NOT_EXPIRED"></a>

Tokens for the customer have expired


<pre><code><b>const</b> <a href="logic.md#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_ETOKENS_NOT_EXPIRED">ETOKENS_NOT_EXPIRED</a>: u64 = 1005;
</code></pre>



<a id="0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_SECS_PER_YEAR"></a>

Creating 1 YEAR as default token expiry time for new minted tokens.


<pre><code><b>const</b> <a href="logic.md#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_SECS_PER_YEAR">SECS_PER_YEAR</a>: u64 = 31536000;
</code></pre>



<a id="0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_SEED_FOR_OBJECT"></a>

Seed value for admin data object


<pre><code><b>const</b> <a href="logic.md#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_SEED_FOR_OBJECT">SEED_FOR_OBJECT</a>: <a href="">vector</a>&lt;u8&gt; = [65, 100, 109, 105, 110, 68, 97, 116, 97, 79, 98, 106, 101, 99, 116];
</code></pre>



<a id="0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_mint_tokens"></a>

## Function `mint_tokens`



<pre><code><b>public</b> entry <b>fun</b> <a href="logic.md#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_mint_tokens">mint_tokens</a>(admin: &<a href="">signer</a>, customer_address: <b>address</b>, amount: u64)
</code></pre>



<a id="0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_redeem_tokens"></a>

## Function `redeem_tokens`



<pre><code><b>public</b> entry <b>fun</b> <a href="logic.md#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_redeem_tokens">redeem_tokens</a>(customer_signer: &<a href="">signer</a>, amount: u64)
</code></pre>



<a id="0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_withdraw_expired_tokens"></a>

## Function `withdraw_expired_tokens`



<pre><code><b>public</b> entry <b>fun</b> <a href="logic.md#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_withdraw_expired_tokens">withdraw_expired_tokens</a>(admin: &<a href="">signer</a>)
</code></pre>



<a id="0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_check_balance"></a>

## Function `check_balance`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="logic.md#0x353c22368abd20066d5a1d94de5c52eb05388b1b492194c5f8e3d9cf3e6dc40c_Practical2_check_balance">check_balance</a>(customer_address: <b>address</b>): u64
</code></pre>
