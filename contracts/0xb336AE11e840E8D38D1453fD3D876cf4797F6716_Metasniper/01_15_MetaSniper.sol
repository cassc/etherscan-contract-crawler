// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IAccessToken {
     function balanceOf(address account, uint256 id) external view returns (uint256);
}


// These contract definitions are used to create a reference to the OpenSea
// ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy {
}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Metasniper is ERC721, ERC721Enumerable, Ownable {
    struct SubscriptionPlan {
        uint256 price;
        uint256 renewalFee;
        uint256 duration;
        uint256 maxSubscribers;
    }

    struct ActiveSubscriptions {
        uint256 tier;
        uint256 Expiration;
    }

    mapping(uint256 => SubscriptionPlan) subscriptionPlans; // tier => plan
    mapping(uint256 => ActiveSubscriptions) subscriptionExpiration; //token => subscription
    mapping(uint256 => uint256) mintedTokens; //token index
    mapping(address => bool) betaBonusClaimed;

    string public tokenImage = "https://ipfs.io/ipfs/QmeLdHLV4g77MtqFgGAf9XC3E9qewqkhkg3s3BbePyMHD4";

    bytes32 public merkleRoot = 0x33fea67cf00c8c26877d7a9a4e31aa3e33a8d9b47c2346dbc6c4fea8ad288a0e;
    address private openSeaProxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    bool private isOpenSeaProxyActive = true;

    address betaAccessToken  = 0xD060910aDa4e41e74920901FbEc6e4E19EF37F9c;
    bool BETA_MINT = false;
    bool SALES_PAUSED = true;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        subscriptionPlans[0] = SubscriptionPlan(
            0.01 ether,
            0.01 ether,
            100,
            1
        );
        subscriptionPlans[1] = SubscriptionPlan(
            0.25 ether,
            0.0888 ether,
            30 days,
            300
        );
    }

    function getBetaTokenCount (address _address) public view returns (uint256) {
        return IERC1155(betaAccessToken).balanceOf(_address, 0);
    } 

    // Create a new plan
    function newSubscriptionPlan(
        uint256 _tier,
        uint256 _price,
        uint256 _renewalFee,
        uint256 _duration,
        uint256 _maxSubscribers
    ) public onlyOwner {
        require(subscriptionPlans[_tier].duration < 1, "Plan already exists");
        subscriptionPlans[_tier] = SubscriptionPlan(
            _price,
            _renewalFee,
            _duration,
            _maxSubscribers
        );
    }

    // Edit a existing plan
    function editSubscriptionPlan(
        uint256 _tier,
        uint256 _price,
        uint256 _renewalFee,
        uint256 _duration,
        uint256 _maxSubscribers
    ) public onlyOwner {
        SubscriptionPlan storage plan = subscriptionPlans[_tier];
        require(plan.duration > 0, "Plan does not exist");

        if (_price != plan.price) {
            subscriptionPlans[_tier].price = _price;
        }

        if (_renewalFee != plan.renewalFee) {
            subscriptionPlans[_tier].renewalFee = _renewalFee;
        }

        if (_duration != plan.duration) {
            subscriptionPlans[_tier].duration = _duration;
        }

        if (_maxSubscribers != plan.maxSubscribers) {
            subscriptionPlans[_tier].maxSubscribers = _maxSubscribers;
        }
    }

    function getSubscriptionExpiration(uint256 _tokenId)
        public
        view
        returns (ActiveSubscriptions memory)
    {
        ActiveSubscriptions memory plan = subscriptionExpiration[_tokenId];
        return plan;
    }

    function checkUserSub(address _user, uint256 _tier) public view returns (uint256){
        for (uint256 i = 0; i < balanceOf(_user); i++) {
            if (checkSubscription(tokenOfOwnerByIndex(_user, i))){
                if (subscriptionExpiration[tokenOfOwnerByIndex(_user, i)].tier == _tier){
                    return subscriptionExpiration[tokenOfOwnerByIndex(_user, i)].Expiration;
                }
            }
        }
        return 0;
    }

    function getSubscriptionPlan(uint256 _tier)
        public
        view
        onlyOwner
        returns (SubscriptionPlan memory)
    {
        SubscriptionPlan memory plan = subscriptionPlans[_tier];
        require(plan.duration > 0, "Plan does not exist");
        return plan;
    }

    function subscribe(uint256 _tokenId) public payable {
        uint256 _tier = subscriptionExpiration[_tokenId].tier;
        SubscriptionPlan memory plan = subscriptionPlans[_tier];
        require(plan.duration > 0, "Plan does not exist");
        require(
            msg.value >= plan.renewalFee,
            "Incorrect value sent for renewal"
        );
        require(ownerOf(_tokenId) == msg.sender, "You do not own this token.");

        uint256 startTimestamp = block.timestamp;

        if (subscriptionExpiration[_tokenId].Expiration < startTimestamp) {
            uint256 expiresTimestamp = startTimestamp + plan.duration;
            subscriptionExpiration[_tokenId] = ActiveSubscriptions(
                _tier,
                expiresTimestamp
            );
        } else {
            uint256 expiresTimestamp = subscriptionExpiration[_tokenId]
                .Expiration + plan.duration;
            subscriptionExpiration[_tokenId] = ActiveSubscriptions(
                _tier,
                expiresTimestamp
            );
        }
    }

    function giftSubscribe(uint256 _tokenId) public payable {
        uint256 _tier = subscriptionExpiration[_tokenId].tier;
        SubscriptionPlan memory plan = subscriptionPlans[_tier];
        require(plan.duration > 0, "Plan does not exist");

        if (msg.sender != owner()) {
            require(
                msg.value >= plan.renewalFee,
                "Incorrect value sent for renewal"
            );
        }

        uint256 startTimestamp = block.timestamp;

        if (subscriptionExpiration[_tokenId].Expiration < startTimestamp) {
            uint256 expiresTimestamp = startTimestamp + plan.duration;
            subscriptionExpiration[_tokenId] = ActiveSubscriptions(
                _tier,
                expiresTimestamp
            );
        } else {
            uint256 expiresTimestamp = subscriptionExpiration[_tokenId]
                .Expiration + plan.duration;
            subscriptionExpiration[_tokenId] = ActiveSubscriptions(
                _tier,
                expiresTimestamp
            );
        }
    }


    // Check if token is expired
    function checkSubscription(uint256 _tokenId) public view returns (bool) {
        ActiveSubscriptions memory plan = getSubscriptionExpiration(_tokenId);
        return plan.Expiration > block.timestamp;
    }

    function getMintedCount(uint256 _tier) internal view returns (uint256) {
        return mintedTokens[_tier];
    }

    function setSalePaused(bool _state) public onlyOwner {
        SALES_PAUSED = _state;
    }

    function setBetaMint(bool _state) public onlyOwner {
        BETA_MINT = _state;
    }

    function betaTokenMint() public payable {
        SubscriptionPlan memory plan = subscriptionPlans[1];
        uint256 mintedCount = getMintedCount(1);
        require(BETA_MINT, "Beta mint over");
        require(getBetaTokenCount(msg.sender) > 0, "Not beta user");
        require(plan.maxSubscribers > mintedCount, "Out of stock");
        require(msg.value >= plan.price, "Incorrect value sent for mint");
        require(!betaBonusClaimed[msg.sender], "Already claimed Beta bonus.");

        uint256 offset = 1000000;
        uint256 tokenId = offset + mintedCount + 1;
        uint256 expiresTimestamp = block.timestamp + (plan.duration * 3);
        subscriptionExpiration[tokenId] = ActiveSubscriptions(
            1,
            expiresTimestamp
        );
        betaBonusClaimed[msg.sender] = true;
        _safeMint(msg.sender, tokenId);
        mintedTokens[1] += 1;
    }
    
    function whiteListMint(bytes32[] calldata _proof) public payable {
        SubscriptionPlan memory plan = subscriptionPlans[1];
        uint256 mintedCount = getMintedCount(1);
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "Invalid proof");

        require(plan.maxSubscribers > mintedCount, "Out of stock");
        require(msg.value >= plan.price, "Incorrect value sent for mint");

        uint256 offset = 1000000;
        uint256 tokenId = offset + mintedCount + 1;
        uint256 expiresTimestamp = block.timestamp + (plan.duration * 2);
        subscriptionExpiration[tokenId] = ActiveSubscriptions(
            1,
            expiresTimestamp
        );
        _safeMint(msg.sender, tokenId);
        mintedTokens[1] += 1;
    }

    function mintNewToken(uint256 _tier) public payable {
        SubscriptionPlan memory plan = subscriptionPlans[_tier];
        uint256 mintedCount = getMintedCount(_tier);

        require(plan.duration > 0, "Plan does not exist");
        require(plan.maxSubscribers > mintedCount, "Out of stock");
        if (msg.sender != owner()) {
            require(msg.value >= plan.price, "Incorrect value sent for mint");
        }
        require(!SALES_PAUSED, "Sales are paused");
        
        uint256 offset = 1000000 * _tier;
        uint256 tokenId = offset + mintedCount + 1;
        uint256 expiresTimestamp = block.timestamp + plan.duration;
        subscriptionExpiration[tokenId] = ActiveSubscriptions(
            _tier,
            expiresTimestamp
        );
        _safeMint(msg.sender, tokenId);
        mintedTokens[_tier] += 1;
    }

    function adminMint(address[] memory tos_, uint256 _tier, uint256 _bonusTime) public payable onlyOwner{
        SubscriptionPlan memory plan = subscriptionPlans[_tier];
        uint256 mintedCount = getMintedCount(_tier);
    
        require(plan.duration > 0, "Plan does not exist");
        require(plan.maxSubscribers >= mintedCount + tos_.length, "Out of stock");

        for (uint256 i = 0; i < tos_.length; i++) { 
            uint256 offset = 1000000 * _tier;
            uint256 tokenId = offset + mintedCount + 1;
            uint256 expiresTimestamp = block.timestamp + (plan.duration * _bonusTime);
            subscriptionExpiration[tokenId + i] = ActiveSubscriptions(
                _tier,
                expiresTimestamp
            );
            _safeMint(tos_[i], tokenId + i);
            mintedTokens[_tier] += 1;
        }
        

    }

    function setmerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function updateTokenImage(string memory _url) public onlyOwner {
        tokenImage = _url;
    }

    function updateOSReg(address _address) public onlyOwner {
        openSeaProxyRegistryAddress = _address;
    }

    function getMetadata(uint256 _tokenId) internal view returns (string memory) {
        ActiveSubscriptions memory plan = subscriptionExpiration[_tokenId];
        string[7] memory parts;
        parts[0] = ', "attributes": [{"trait_type": "Tier","value": "';
        parts[1] = toString(plan.tier);
        parts[2] = '"}, {"trait_type": "Expiration","value": "';
        parts[3] = toString(plan.Expiration);
        parts[4] = '"}, {"trait_type": "Expired","value": "';
        parts[5] = plan.Expiration < block.timestamp ? "true" : "false";
        parts[6] = '"}], ';
        
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
        return output;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token."
        );

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Metasniper Access Token", "description": "Access to Metasniper private community and tools."', getMetadata(tokenId), '"image": "',tokenImage,'"}'))));
        json = string(abi.encodePacked('data:application/json;base64,', json));
        return json;

    }


    //required by Solidity
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    //required by Solidity
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Override isApprovedForAll to allowlist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Get a reference to OpenSea's proxy registry contract by instantiating
        // the contract using the already existing address.
        ProxyRegistry proxyRegistry = ProxyRegistry(
            openSeaProxyRegistryAddress
        );
        if (
            isOpenSeaProxyActive &&
            address(proxyRegistry.proxies(owner)) == operator
        ) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    // function to disable gasless listings for security in case
    // opensea ever shuts down or is compromised
    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive)
        external
        onlyOwner
    {
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}