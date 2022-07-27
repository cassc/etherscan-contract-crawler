// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./PackWoodERC721StorageV1.sol";

/**
 * @dev Implementation of the {PackWoodERC721V2}.
 *
 */

contract PackWoodERC721V2 is
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable,
    PackWoodERC721StorageV1
{
    using StringsUpgradeable for uint256;

    // modifiers
    modifier onlyGenOne(uint256 tokenId) {
        require(
            (tokenId >= 866 && tokenId <= 10420) || checkTokenId[tokenId],
            "$MONSTERBUDS: Only generation 1 monsterbuds can process"
        );
        _;
    }

    modifier onlyAllowed() {
        if (!publicAccess) {
            require(allowedAddress[msg.sender], "$MONSTERBUDS: Not allowed");
        }
        _;
    }

    // functions

    /**
     * @dev adds to generation one token list.
     *
     * @param _data array of token id.
     *
     * Requirements:
     * - only owner can update value.
     */

    function updateGenerationOneTokens(uint256[] calldata _data)
        external
        virtual
        onlyOwner
    {
        for (uint256 i = 0; i < _data.length; i++) {
            checkTokenId[_data[i]] = true;
        }
    }

    /**
     * @dev updates access of all function details.
     *
     * @param _address array of address
     * @param _status allowed address status
     * @param _public_access_status public access status to all function
     *
     * Requirements:
     * - only owner can update value.
     */

    function updateAllowedAddress(
        address[] calldata _address,
        bool _status,
        bool _public_access_status
    ) external virtual onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            allowedAddress[_address[i]] = _status;
        }
        publicAccess = _public_access_status;
    }

    /**
     * @dev concate the URI string for respective token ID.
     *
     * @param before_ before part of token URI
     * @param _token_id token id
     * @param after_ after part of token URI
     *
     * Requirements:
     * - only owner can update value.
     */

    function uriConcate(
        string memory before_,
        uint256 _token_id,
        string memory after_
    ) private pure returns (string memory) {
        string memory token_uri = string(
            abi.encodePacked(before_, _token_id.toString(), after_)
        );
        return token_uri;
    }

    /**
     * @dev calculates the fee
     *
     * @param _totalPrice total price
     *
     */
    function feeCalulation(uint256 _totalPrice) private view returns (uint256) {
        uint256 fee = feeMargin * _totalPrice;
        uint256 fees = fee / 1000;
        return fees;
    }

    /**
     * @dev update the fee margin.
     *
     * @param nextMargin fee margin percent
     *
     * Requirements:
     * - only owner can update value.
     */
    function updateFeeMargin(uint256 nextMargin)
        external
        onlyOwner
        returns (uint256)
    {
        feeMargin = nextMargin; // update fee percent
        return feeMargin;
    }

    /**
     * @dev updates the monster buds contract address
     *
     * @param _address contract address
     *
     * Requirements:
     * - only owner can update value.
     */

    function updateMonsterAddress(address _address)
        external
        onlyOwner
        returns (bool)
    {
        MonsterParent = IERC721(_address);
        return true;
    }

    /**
     * @dev updated the purchase status
     *
     * @param _status status in boolean
     *
     * Requirements:
     * - only owner can update value.
     */
    function updateBuyStatus(bool _status) external onlyOwner returns (bool) {
        buyONorOFFstatus = _status;
        return buyONorOFFstatus;
    }

    /**
     * @dev updates the ERC1155 contract address
     *
     * @param _parentAddress contract address
     *
     * Requirements:
     * - only owner can update value.
     */
    function updateParentAddress(address _parentAddress)
        external
        onlyOwner
        returns (bool)
    {
        ERC1155Parent = IPackWoodERC1155(_parentAddress);
        return true;
    }

    /**
     * @dev updates the PFP ETH value
     *
     * @param _value PFP price
     *
     * Requirements:
     * - only owner can update value.
     */
    function updatePfpValue(uint256 _value) external onlyOwner returns (bool) {
        pfpValue = _value;
        return true;
    }

    /**
     * @dev updates the token URI before and after part.
     *
     * @param before_ before part of token URI
     * @param after_ after part of token URI
     *
     * Requirements:
     * - only owner can update value.
     */
    function setTokenUri(string memory before_, string memory after_)
        external
        onlyOwner
        returns (bool)
    {
        _before = before_;
        _after = after_;
        return true;
    }

    /**
     * @dev updates the breed ETH value
     *
     * @param _ethValue eth value
     *
     * Requirements:
     * - only owner can update value.
     */
    function updateBreedValue(uint256 _ethValue)
        external
        onlyOwner
        returns (uint256)
    {
        breedValue = _ethValue; // update the eth value of breed value
        return breedValue;
    }

    /**
     * @dev updates the status for breed.
     *
     * @param _status status in boolean.
     *
     * Requirements:
     * - only owner can update value.
     */
    function updateSelfBreedStatus(bool _status)
        external
        onlyOwner
        returns (bool)
    {
        selfBreedStatus = _status;
        return selfBreedStatus;
    }

    /**
     * @dev updates the smartcontract community wallet address
     *
     * @param nextOwner wallet address
     *
     * Requirements:
     * - only owner can update value.
     */
    function updateSmartContractCommunity(address payable nextOwner)
        external
        onlyOwner
        returns (address)
    {
        require(
            nextOwner != address(0x00),
            "$MONSTERBUDS: cannot be zero address"
        );
        SmartContractCommunity = nextOwner; // update the fee wallet for SKT
        return SmartContractCommunity;
    }

    /**
     * @dev updates the SKT fee wallet
     *
     * @param nextOwner wallet address
     *
     * Requirements:
     * - only owner can update value.
     */
    function updateFeeSKTWallet(address payable nextOwner)
        external
        onlyOwner
        returns (address)
    {
        require(
            nextOwner != address(0x00),
            "$MONSTERBUDS: cannot be zero address"
        );
        feeSKTWallet = nextOwner; // update the fee wallet for SKT
        return feeSKTWallet;
    }

    /**
     * @dev Game process for creating new child monster buds
     *
     * @param _monsterTokenId monsterbud contract token id(generation one)
     * @param _packwoodERC1155TokenId sereum token Id
     *
     * returns:
     * - token id.
     *
     * Emits a {createChild} event.
     */

    function process(uint256 _monsterTokenId, uint256 _packwoodERC1155TokenId)
        external
        virtual
        onlyAllowed
        onlyGenOne(_monsterTokenId)
        returns (uint256)
    {
        require(
            MonsterParent.ownerOf(_monsterTokenId) == msg.sender,
            "PackwoodERC721: You are not owner of token"
        );

        // create new ERC721 packwood token
        newItemId = tokenCounter;
        string memory _uri = uriConcate(_before, newItemId, _after);
        _safeMint(msg.sender, newItemId); // mint new seed
        _setTokenURI(newItemId, _uri); // set uri to new seed

        tokenCounter += 1;

        // storing breed Information For child
        breedInfomation storage new_data = breedInfo[newItemId];
        new_data.tokenId = newItemId;
        new_data.breedCount = 0;
        new_data.timstamp = block.timestamp + 4 days;

        // burn the ERC1155 packwood token
        ERC1155Parent.burnToken(msg.sender, _packwoodERC1155TokenId);

        // emit event
        emit createChild(_monsterTokenId, _packwoodERC1155TokenId, newItemId);

        return newItemId;
    }

    /**
     * @dev self breed between token ids to create new child token
     *
     * @param breed breed structure order
     * @param signature signature
     *
     * returns:
     * - bool.
     *
     * Emits a {breedSelf} event.
     */

    function selfBreedCollectiable(
        SelfBreed calldata breed,
        bytes calldata signature
    ) external payable virtual onlyAllowed returns (uint256) {
        bool status = SignatureCheckerUpgradeable.isValidSignatureNow(
            owner(),
            breed.signKey,
            signature
        );
        require(status == true, "$PackwoodERC721: cannot breed[ERROR]");
        require(
            breedValue == msg.value,
            "$PackwoodERC721: Amount is incorrect"
        );

        // owners of token id
        address owner_req = (ownerOf(breed.req_token_id));
        address owner_accept = (ownerOf(breed.accept_token_id));

        //
        require(selfBreedStatus == true, "$PackwoodERC721: Breeding is closed");
        require(
            owner_req == owner_accept &&
                owner_req == msg.sender &&
                breed.req_token_id != breed.accept_token_id,
            "$PackwoodERC721: Cannot Self Breed"
        );
        require(
            breedInfo[breed.req_token_id].breedCount < 2 &&
                breedInfo[breed.accept_token_id].breedCount < 2,
            "$PackwoodERC721: Exceeds max breed count"
        );
        require(
            block.timestamp >= breedInfo[breed.req_token_id].timstamp &&
                block.timestamp >= breedInfo[breed.accept_token_id].timstamp,
            "$PackwoodERC721: cannot breed now"
        );

        // setting token URI
        newItemId = tokenCounter;
        string memory seed_token_uri = uriConcate(_before, newItemId, _after);

        _safeMint(msg.sender, newItemId); // mint new child seed
        _setTokenURI(newItemId, seed_token_uri); // set child uri
        uint256 countOfReq = breedInfo[breed.req_token_id].breedCount;
        uint256 countOfAccept = breedInfo[breed.accept_token_id].breedCount;

        //
        breedInfomation storage new_data = breedInfo[newItemId];
        new_data.tokenId = newItemId;
        new_data.breedCount = 0;
        new_data.timstamp = block.timestamp + 4 days;

        tokenCounter = tokenCounter + 1;
        breedInfomation storage req_data = breedInfo[breed.req_token_id];
        req_data.tokenId = breed.req_token_id;
        req_data.breedCount = countOfReq + 1;
        req_data.timstamp = block.timestamp + 1512000;

        breedInfomation storage accept_data = breedInfo[breed.accept_token_id];
        accept_data.tokenId = breed.accept_token_id;
        accept_data.breedCount = countOfAccept + 1;
        accept_data.timstamp = block.timestamp + 1512000;

        payable(feeSKTWallet).transfer(msg.value); // send 0.008 to skt fee wallet

        emit breedSelf(
            msg.sender,
            breed.req_token_id,
            breed.accept_token_id,
            seed_token_uri,
            newItemId,
            msg.value
        );

        return newItemId;
    }

    /**
     * @dev order check where the purchase has been handled.
     */
    function orderCheck(Order memory order) private returns (bool) {
        address payable owner = payable(ownerOf(order.token_id));
        bytes32 hashS = keccak256(abi.encodePacked(msg.sender));
        bytes32 hashR = keccak256(abi.encodePacked(owner));
        bytes32 hashT = keccak256(abi.encodePacked(order.price));
        bytes32 hashV = keccak256(abi.encodePacked(order.token_id));
        bytes32 hashP = keccak256(abi.encodePacked(order.expiryTimestamp));
        bytes32 sign = keccak256(
            abi.encodePacked(hashV, hashP, hashT, hashR, hashS)
        );

        require(
            order.expiryTimestamp >= block.timestamp,
            "MONSTERBUDS: expired time"
        );
        require(sign == order.signKey, "$MONSTERBUDS: ERROR");
        require(order.price == msg.value, "MONSTERBUDS: Price is incorrect");

        uint256 feeAmount = feeCalulation(msg.value);
        payable(feeSKTWallet).transfer(feeAmount); // transfer 5% ethers of msg.value to skt fee wallet
        payable(SmartContractCommunity).transfer(feeAmount); // transfer 5% ethers of msg.value to commuinty

        uint256 remainAmount = msg.value - (feeAmount + feeAmount);
        payable(order.owner).transfer(remainAmount); // transfer remaining 90% ethers of msg.value to owner of token
        _transfer(order.owner, msg.sender, order.token_id); // transfer the ownership of token to buyer

        emit buyTransfer(order.owner, msg.sender, order.token_id, msg.value);
        return true;
    }

    /**
     * @dev purchase function to buy listed token
     *
     * @param order order structure
     * @param signature signature
     *
     * returns:
     * - bool
     *
     * Emits a {buyTransfer} event.
     */

    function purchase(Order memory order, bytes memory signature)
        external
        payable
        virtual
        onlyAllowed
        returns (bool)
    {
        require(
            buyONorOFFstatus == true,
            "$MONSTERBUDS: Marketplace for buying is closed"
        );
        orderCheck(order);
        bool status = SignatureCheckerUpgradeable.isValidSignatureNow(
            owner(),
            order.signature,
            signature
        );
        require(status == true, "$MONSTERBUDS: cannot purchase the token");
        return true;
    }

    /**
     * @dev upgrade the token to PFP version
     *
     * @param token_id token id
     *
     * returns:
     * - bool.
     *
     * Emits a {PfpDetails} event.
     */

    function createPfpVersion(uint256 token_id)
        external
        payable
        virtual
        onlyAllowed
        returns (bool)
    {
        require(msg.value == pfpValue, "$MONSTERBUDS: Price is incorrect");
        require(
            ownerOf(token_id) == msg.sender,
            "$MONSTERBUDS: You are not owner of token"
        );

        payable(feeSKTWallet).transfer(msg.value);

        emit PfpDetails(msg.sender, token_id, msg.value);
        return true;
    }

    /**
     * @dev self breed between token ids to create new child token
     *
     * @param breed breed structure order
     * @param signature signature
     *
     * returns:
     * - token id.
     *
     * Emits a {monsterPackwoodSelfBreed} event.
     */

    function selfBreedMonsterBuds(
        SelfBreed calldata breed,
        bytes calldata signature
    ) external payable virtual onlyAllowed returns (uint256) {
        bool status = SignatureCheckerUpgradeable.isValidSignatureNow(
            owner(),
            breed.signKey,
            signature
        );
        require(status == true, "$PackwoodERC721: cannot breed[ERROR]");
        require(
            breedValue == msg.value,
            "$PackwoodERC721: Amount is incorrect"
        );

        address owner_req = (MonsterParent.ownerOf(breed.req_token_id));
        address owner_accept = (ownerOf(breed.accept_token_id));

        require(selfBreedStatus == true, "$PackwoodERC721: Breeding is closed");
        require(
            owner_req == owner_accept && owner_req == msg.sender,
            "$PackwoodERC721: Cannot Self Breed"
        );
        require(
            breedInfo[breed.accept_token_id].breedCount < 2,
            "$PackwoodERC721: Exceeds max breed count"
        );
        require(
            block.timestamp >= breedInfo[breed.accept_token_id].timstamp,
            "$PackwoodERC721: cannot breed now"
        );

        uint256 countOfAccept = breedInfo[breed.accept_token_id].breedCount;

        breedInfomation storage accept_data = breedInfo[breed.accept_token_id];
        accept_data.tokenId = breed.accept_token_id;
        accept_data.breedCount = countOfAccept + 1;
        accept_data.timstamp = block.timestamp + 1512000;

        uint256 newItem = MonsterParent.breedUpdation(
            breed.req_token_id,
            msg.sender
        );

        payable(feeSKTWallet).transfer(msg.value); // send 0.008 to skt fee wallet

        emit monsterPackwoodSelfBreed(
            msg.sender,
            breed.req_token_id,
            breed.accept_token_id,
            MonsterParent.tokenURI(newItem),
            newItem,
            msg.value
        );

        return newItemId;
    }
}