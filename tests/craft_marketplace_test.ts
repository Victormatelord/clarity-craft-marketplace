import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can list a new item with category",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('craft_marketplace', 'list-item', [
                types.uint(1),
                types.ascii("Handmade Scarf"),
                types.utf8("Beautiful winter scarf"),
                types.uint(100000000), // 100 STX
                types.ascii("crafts"),
                types.uint(100) // expires in 100 blocks
            ], wallet1.address)
        ]);
        
        assertEquals(block.receipts[0].result.expectOk(), true);
    },
});

Clarinet.test({
    name: "Cannot list item with invalid category",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('craft_marketplace', 'list-item', [
                types.uint(1),
                types.ascii("Handmade Scarf"),
                types.utf8("Beautiful winter scarf"),
                types.uint(100000000),
                types.ascii("invalid"),
                types.uint(100)
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectErr();
    },
});

Clarinet.test({
    name: "Can purchase a listed item before expiry",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const seller = accounts.get('wallet_1')!;
        const buyer = accounts.get('wallet_2')!;
        
        // List an item
        let block = chain.mineBlock([
            Tx.contractCall('craft_marketplace', 'list-item', [
                types.uint(1),
                types.ascii("Handmade Scarf"),
                types.utf8("Beautiful winter scarf"),
                types.uint(100000000),
                types.ascii("crafts"),
                types.uint(100)
            ], seller.address)
        ]);
        
        // Purchase it
        let purchaseBlock = chain.mineBlock([
            Tx.contractCall('craft_marketplace', 'purchase-item', [
                types.principal(seller.address),
                types.uint(1)
            ], buyer.address)
        ]);
        
        purchaseBlock.receipts[0].result.expectOk();
    },
});
