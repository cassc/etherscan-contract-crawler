pragma solidity 0.8.8;

library DFStorage {
    /**
    @notice This struct is a source of mapping-free input to the `addPool` function.

    @param name A name for the pool.
    @param startTime The timestamp when this pool begins allowing purchases.
    @param endTime The timestamp after which this pool disallows purchases.
    @param purchaseLimit The maximum number of items a single address may
      purchase from this pool.
    @param singlePurchaseLimit The maximum number of items a single address may
      purchase from this pool in a single transaction.
    @param requirement A PoolRequirement requisite for users who want to
      participate in this pool.
  */
    struct PoolInput {
        string name;
        uint256 startTime;
        uint256 endTime;
        uint256 purchaseLimit;
        uint256 singlePurchaseLimit;
        PoolRequirement requirement;
        address collection;
    }

    /**
    @notice This enumeration type specifies the different access rules that may be
    applied to pools in this shop. Access to a pool may be restricted based on
    the buyer's holdings of either tokens or items.

    @param Public This specifies a pool which requires no special asset holdings
      to buy from.
    @param TokenRequired This specifies a pool which requires the buyer to hold
      some amount of ERC-20 tokens to buy from.
    @param ItemRequired This specifies a pool which requires the buyer to hold
      some amount of an ERC-1155 item to buy from.
    @param PointRequired This specifies a pool which requires the buyer to hold
      some amount of points in a Staker to buy from.
  */
    enum AccessType {
        Public,
        TokenRequired,
        ItemRequired,
        PointRequired,
        ItemRequired721
    }

    /**
    @notice This struct tracks information about a prerequisite for a user to
    participate in a pool.

    @param requiredType The `AccessType` being applied to gate buyers from
      participating in this pool. See `requiredAsset` for how additional data
      can apply to the access type.
    @param requiredAsset Some more specific information about the asset to
      require. If the `requiredType` is `TokenRequired`, we use this address to
      find the ERC-20 token that we should be specifically requiring holdings
      of. If the `requiredType` is `ItemRequired`, we use this address to find
      the item contract that we should be specifically requiring holdings of. If
      the `requiredType` is `PointRequired`, we treat this address as the
      address of a Staker contract. Do note that in order for this to work, the
      Staker must have approved this shop as a point spender.
    @param requiredAmount The amount of the specified `requiredAsset` required
      for the buyer to purchase from this pool.
    @param requiredId The ID of an address whitelist to restrict participants
      in this pool. To participate, a purchaser must have their address present
      in the corresponding whitelist. Other requirements from `requiredType`
      also apply. An ID of 0 is a sentinel value for no whitelist required.
  */
    struct PoolRequirement {
        AccessType requiredType;
        address[] requiredAsset;
        uint256 requiredAmount;
        uint256[] requiredId;
    }

    /**
    @notice This enumeration type specifies the different assets that may be used to
    complete purchases from this mint shop.

    @param Point This specifies that the asset being used to complete
      this purchase is non-transferrable points from a `Staker` contract.
    @param Ether This specifies that the asset being used to complete
      this purchase is native Ether currency.
    @param Token This specifies that the asset being used to complete
      this purchase is an ERC-20 token.
  */
    enum AssetType {
        Point,
        Ether,
        Token
    }

    /**
    @notice This struct tracks information about a single asset with the associated
    price that an item is being sold in the shop for. It also includes an
    `asset` field which is used to convey optional additional data about the
    asset being used to purchase with.

    @param assetType The `AssetType` type of the asset being used to buy.
    @param asset Some more specific information about the asset to charge in.
     If the `assetType` is Point, we use this address to find the specific
     Staker whose points are used as the currency.
     If the `assetType` is Ether, we ignore this field.
     If the `assetType` is Token, we use this address to find the
     ERC-20 token that we should be specifically charging with.
    @param price The amount of the specified `assetType` and `asset` to charge.
  */
    struct Price {
        AssetType assetType;
        address asset;
        uint256 price;
    }
  /**
    This enumeration lists the various supply types that each item group may
    use. In general, the administrator of this collection or those permissioned
    to do so may move from a more-permissive supply type to a less-permissive.
    For example: an uncapped or flexible supply type may be converted to a
    capped supply type. A capped supply type may not be uncapped later, however.

    @param Capped There exists a fixed cap on the size of the item group. The
      cap is set by `supplyData`.
    @param Uncapped There is no cap on the size of the item group. The value of
      `supplyData` cannot be set below the current circulating supply but is
      otherwise ignored.
    @param Flexible There is a cap which can be raised or lowered (down to
      circulating supply) freely. The value of `supplyData` cannot be set below
      the current circulating supply and determines the cap.
  */
  enum SupplyType {
    Capped,
    Uncapped,
    Flexible
  }

  /**
    This enumeration lists the various item types that each item group may use.
    In general, these are static once chosen.

    @param Nonfungible The item group is truly nonfungible where each ID may be
      used only once. The value of `itemData` is ignored.
    @param Fungible The item group is truly fungible and collapses into a single
      ID. The value of `itemData` is ignored.
    @param Semifungible The item group may be broken up across multiple
      repeating token IDs. The value of `itemData` is the cap of any single
      token ID in the item group.
  */
  enum ItemType {
    Nonfungible,
    Fungible,
    Semifungible
  }

  /**
    This enumeration lists the various burn types that each item group may use.
    These are static once chosen.

    @param None The items in this group may not be burnt. The value of
      `burnData` is ignored.
    @param Burnable The items in this group may be burnt. The value of
      `burnData` is the maximum that may be burnt.
    @param Replenishable The items in this group, once burnt, may be reminted by
      the owner. The value of `burnData` is ignored.
  */
  enum BurnType {
    None,
    Burnable,
    Replenishable
  }

  /**
    This struct is a source of mapping-free input to the `configureGroup`
    function. It defines the settings for a particular item group.
   
    @param supplyData An optional integer used by some `supplyType` values.
    @param itemData An optional integer used by some `itemType` values.
    @param burnData An optional integer used by some `burnType` values.
    @param name A name for the item group.
    @param supplyType The supply type for this group of items.
    @param itemType The type of item represented by this item group.
    @param burnType The type of burning permitted by this item group.
    
  */
  struct ItemGroupInput {
    uint256 supplyData;
    uint256 itemData;
    uint256 burnData;
    SupplyType supplyType;
    ItemType itemType;
    BurnType burnType;
    string name;
  }


  /**
    This structure is used at the moment of NFT purchase.
    @param whiteListId Id of a whiteList.
    @param index Element index in the original array
    @param allowance The quantity is available to the user for purchase.
    @param node Base hash of the element.
    @param merkleProof Proof that the user is on the whitelist.
  */
  struct WhiteListInput {
    uint256 whiteListId;
    uint256 index; 
    uint256 allowance;
    bytes32 node; 
    bytes32[] merkleProof;
  }


  /**
    This structure is used at the moment of NFT purchase.
    @param _accesslistId Id of a whiteList.
    @param _merkleRoot Hash root of merkle tree.
    @param _startTime The start date of the whitelist
    @param _endTime The end date of the whitelist
    @param _price The price that applies to the whitelist
    @param _token Token with which the purchase will be made
  */
  struct WhiteListCreate {
    uint256 _accesslistId;
    bytes32 _merkleRoot;
    uint256 _startTime; 
    uint256 _endTime; 
    uint256 _price; 
    address _token;
  }
}