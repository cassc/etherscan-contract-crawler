// SPDX-License-Identifier: Unlicense
// Creator: 0xYeety/YEETY.eth - Co-Founder/CTO, Virtue Labs

pragma solidity ^0.8.17;

//import "./ERC721Y_A.sol";
//import "./ERC721Y.sol";
import "./ERC721Keys.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/operator-filter-registry/src/DefaultOperatorFilterer.sol";
//import "./SkeleKeysRepo.sol";

//contract SkeleKeys is ERC721Y, Ownable {
contract SkeleKeys is ERC721Keys, Ownable, DefaultOperatorFilterer {
    using Address for address;
    using Strings for uint256;
    string public PROVENANCE;
    bool provenanceSet;

    address public skelephunksAddr;

    mapping(address => bool) private _allocationAuthorizations;

    uint256 private _nonce;

    bool public initialized = false;

    mapping(address => bool) public _isBurnAddress;

    string public _collectionImg;
    string public _collectionDescription;
    string public _externalLink;

    modifier onlyAuthorized() {
        _isAuthorized();
        _;
    }

    function _isAuthorized() internal view virtual {
        require(msg.sender == skelephunksAddr || _allocationAuthorizations[msg.sender], "aa");
    }

    mapping(uint256 => uint256) private _keysToMintOrders;
    mapping(address => uint256) private _numClaimed;


    bool private royaltySwitch = true;
    modifier onlyAllowedOperator(address from) virtual override {
        if (royaltySwitch) {
            if (from != msg.sender) {
                _checkFilterOperator(msg.sender);
            }
        }
        _;
    }
    modifier onlyAllowedOperatorApproval(address operator) virtual override {
        if (royaltySwitch) {
            _checkFilterOperator(operator);
        }
        _;
    }


    constructor(
        address skelephunksAddr_
    ) ERC721Keys('SkeleKeys', 'SKEYS') {
        skelephunksAddr = skelephunksAddr_;

        // Addresses marked as burn addresses by Etherscan
        _isBurnAddress[0x000000000000000000000000000000000000dEaD] = true;
        _isBurnAddress[0x0000000000000000000000000000000000000000] = true;
        _isBurnAddress[0x0000000000000000000000000000000000000001] = true;
        _isBurnAddress[0x0000000000000000000000000000000000000002] = true;
        _isBurnAddress[0x0000000000000000000000000000000000000003] = true;
        _isBurnAddress[0x0000000000000000000000000000000000000004] = true;
        _isBurnAddress[0x0000000000000000000000000000000000000005] = true;
        _isBurnAddress[0x0000000000000000000000000000000000000006] = true;
        _isBurnAddress[0x0000000000000000000000000000000000000007] = true;
        _isBurnAddress[0x0000000000000000000000000000000000000008] = true;
        _isBurnAddress[0x0000000000000000000000000000000000000009] = true;
        _isBurnAddress[0x00000000000000000000045261D4Ee77acdb3286] = true;
        _isBurnAddress[0x1111111111111111111111111111111111111111] = true;
        _isBurnAddress[0x1234567890123456789012345678901234567890] = true;
        _isBurnAddress[0x2222222222222222222222222222222222222222] = true;
        _isBurnAddress[0x3333333333333333333333333333333333333333] = true;
        _isBurnAddress[0x4444444444444444444444444444444444444444] = true;
        _isBurnAddress[0x8888888888888888888888888888888888888888] = true;
        _isBurnAddress[0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa] = true;
        _isBurnAddress[0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB] = true;
        _isBurnAddress[0xdEAD000000000000000042069420694206942069] = true;
        _isBurnAddress[0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE] = true;
        _isBurnAddress[0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF] = true;
    }

    function initNonce() private {
        _nonce = getRandomNumber(msg.sender);
    }

    function initKeys(address to) private {
        _mint(to, 13);
    }

    function initialize() public onlyOwner {
        require(!initialized, "init");
        initNonce();
        initKeys(address(this));

        uint256 randNum = getRandomNumber(address(this));
        _nonce += (randNum>>13)%666;
        randNum = getRandomNumber(address(this));
        for (uint256 i = 0; i < 13; i++) {
            uint256 randOrder = ((randNum>>(i*9))%512)+1 + (512*i);
            if (i == 12) {
                randOrder = ((randNum>>(i*9))%522)+1 + (512*i);
            }

            _keysToMintOrders[i + 1] = randOrder;
        }

        initialized = true;
    }

    function setAuthorizationStatus(address addr, bool authStatus) public onlyOwner {
        _allocationAuthorizations[addr] = authStatus;
        setApprovalForSelf(addr, authStatus);
    }

    function getRandomNumber(address msgSender) private view returns (uint256) {
        return uint256(
            keccak256(
                abi.encode(
                    msgSender,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1),
                    address(this),
                    _nonce
                )
            )
        );
    }

    function getRandomKeyToAllocate(address to) public view returns(uint256) {
        uint256 supply = totalSupply();
        uint256 numRemaining = balanceOf(address(this));
        uint256 randNum = getRandomNumber(to);

        uint256 spotToAllocate = randNum%numRemaining;

        uint256 curIndex = 0;
        uint256 toReturn = 0;
        uint256 toReturnFake = 0;
        for (uint256 i = 1; i <= supply; i++) {
            if (ownerOf(i) == address(this)) {
                if (curIndex == spotToAllocate) {
                    toReturn = i;
                }
                else {
                    toReturnFake = i;
                }
                curIndex++;
            }
        }

        if (toReturn > 0) {
            return toReturn;
        }

        revert("u");
    }

    function allocateRandomKey(address to) public onlyAuthorized {
        _arkInternal(to);
    }

    function _arkInternal(address to) private {
        uint256 keyToAllocate = getRandomKeyToAllocate(to);
        _nonce += (1 + keyToAllocate);

        approveForSelf(to, keyToAllocate);
        transferFrom(address(this), to, keyToAllocate);
    }

    function allocateKeyTo(address to, uint256 whichKey) private {
        transferFrom(ownerOf(whichKey), to, whichKey);
    }

    ////////////////////

    function unclaimedOf(address addr) public view returns (uint256) {
        uint256 toReturn = 0;
        uint256 highestClaimable = 0;
        uint256 highestClaimableTime = 0;

        for (uint256 i = 13; i > 0; i--) {
            uint256 keyMintIndex = _keysToMintOrders[i];
            if (addr == SkelephunksProto(skelephunksAddr).getMinterByOrderIndex(keyMintIndex)) {
                toReturn += 1;
                if (highestClaimable == 0) {
                    highestClaimable = keyMintIndex;
                    highestClaimableTime = SkelephunksProto(skelephunksAddr).getMintTimeByOrderIndex(keyMintIndex);
                }
            }
        }

        if (toReturn == 0) {
            return 0;
        }

        if ((block.timestamp - highestClaimableTime) > 7 days) {
            return 0;
        }

        toReturn -= _numClaimed[addr];

        return toReturn;
    }

    function getClaimDeadline(address addr) public view returns (uint256) {
        for (uint256 i = 13; i > 0; i--) {
            uint256 keyMintIndex = _keysToMintOrders[i];
            if (addr == SkelephunksProto(skelephunksAddr).getMinterByOrderIndex(keyMintIndex)) {
                uint256 deadlineSeconds = SkelephunksProto(skelephunksAddr).getMintTimeByOrderIndex(keyMintIndex) + (7 days);
                return (deadlineSeconds*1000);
            }
        }

        revert("nf");
    }

    function claimKeys() public {
        uint256 unclaimedKeys = unclaimedOf(msg.sender);
        require(unclaimedKeys > 0, "nu");

        for (uint256 i = 0; i < unclaimedKeys; i++) {
            _arkInternal(msg.sender);
        }

        _numClaimed[msg.sender] += unclaimedKeys;
    }

    function redeemKey(uint256 keyId) public onlyAuthorized {
        require(tx.origin == ownerOf(keyId), "not ur key, not ur phunks");
        _transferToSelf(tx.origin, address(this), keyId);
    }

    function resurrectKey(uint256 keyId) public {
        require(_isBurnAddress[ownerOf(keyId)]);
        _transferToSelf(ownerOf(keyId), address(this), keyId);
    }

    //////////

    function setPreRevealURI(string memory preRevealURI_) public onlyOwner {
        _setPreRevealURI(preRevealURI_);
    }

    function setBasedURI(string memory basedURI_) public onlyOwner {
        _setBasedURI(basedURI_);
    }

    //////////

    function setCollectionDescription(string memory __collectionDescription) public onlyOwner {
        _collectionDescription = __collectionDescription;
    }

    function setCollectionImg(string memory __collectionImg) public onlyOwner {
        _collectionImg = __collectionImg;
    }

    function setExternalLink(string memory __externalLink) public onlyOwner {
        _externalLink = __externalLink;
    }

    function contractURI() public view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;utf8,{\"name\":\"", name(),"\",",
                "\"description\":\"", _collectionDescription, "\",",
                "\"image\":\"", _collectionImg, "\",",
                "\"external_link\":\"", _externalLink, "\",",
                "\"seller_fee_basis_points\":666,\"fee_recipient\":\"",
                uint256(uint160(skelephunksAddr)).toHexString(), "\"}"
            )
        );
    }

    function flipRoyaltySwitch() public onlyOwner {
        royaltySwitch = !royaltySwitch;
    }

    //////////

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    //////////

    function sendKeyFundsToSkelephunksContract() public {
        require(SkelephunksProto(skelephunksAddr).isPayee(msg.sender), "nspp");
        (bool success1, ) = payable(skelephunksAddr).call{value: address(this).balance}("");
        require(success1, "F");
    }

    function sendKeyTokenFundsToSkelephunksContract(address tokenAddress) public {
        require(SkelephunksProto(skelephunksAddr).isPayee(msg.sender), "nspp");
        IERC20(tokenAddress).transfer(skelephunksAddr, IERC20(tokenAddress).balanceOf(address(this)));
    }
}

////////////////////

abstract contract SkelephunksProto {
//    function mintReserve(
//        address _to,
//        uint256 _quantity,
//        uint256 genderDirection
//    ) public virtual;

    function getMinterByOrderIndex(uint256 index) public view virtual returns (address);
    function getMintTimeByOrderIndex(uint256 index) public view virtual returns (uint64);
    function isPayee(address addr) public view virtual returns (bool);
}

////////////////////////////////////////