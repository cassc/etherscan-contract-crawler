// SPDX-License-Identifier: MIT OR Apache-2.0
// Author: Luca Di Domenico: twitter.com/luca_dd7
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

// import "hardhat/console.sol";

contract DragonNFT is ERC721Royalty, Ownable, AccessControl, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _mintedNFTs;
    uint8 public step;
    uint256 public totalSupply = 10000;
    uint256 constant firstSaleMaxCnt = 2000;
    uint256 constant secondSaleMaxCnt = 6000;
    uint256 constant thirdSaleMaxCnt = 10000;
    string public baseURI =
        "ipfs://bafybeiazke2lkvece5tupum57nl2cnkxbujtxflia7wpn727glsnnzpaem/";

    mapping(uint256 => address) receiving_addresses;
    address public royalty_receiver =
        0xe0Cb4eECe898456B33ae9bc4042a64bdD86B3654;
    uint256 public royalty_amount = 500; //0.5% in bp
    bytes32 private _merkleRootWhitelisted =
        0xedc55d223384f37b436e36643bbe403eb1aed4eeb2ab82d2f0f45894d28a0e8e;

    bytes32 public constant DEVELOPER = keccak256("DEVELOPER");

    /*
    * Chainlink VRF config
    */

    VRFCoordinatorV2Interface COORDINATOR;
    uint64 public s_subscriptionId;
    address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    bytes32 keyHash =
        0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
    uint32 public callbackGasLimit = 2000000;
    uint16 requestConfirmations = 3;

    event newNFTMinted(uint256, address);

    modifier onlyDeveloper() {
        require(hasRole(DEVELOPER, msg.sender), "The account does not have DEVELOPER role.");
        _;
    }

    constructor(uint64 _subscriptionId, uint8 _step)
        ERC721("VoltedDragonsSailorsClub", "VDSC")
        VRFConsumerBaseV2(vrfCoordinator)
    {
        _grantRole(
            DEFAULT_ADMIN_ROLE,
            0xB1A6461A733215bE98f10fE6C30CaF0d7716615A
        );
        _grantRole(DEVELOPER, 0xB1A6461A733215bE98f10fE6C30CaF0d7716615A);
        _grantRole(DEVELOPER, msg.sender);
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = _subscriptionId;
        step = _step;
    }

    function requestRandomWords(uint32 _quantity) internal {
        // Will revert if subscription is not set and funded.
        uint256 s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            _quantity
        );
        receiving_addresses[s_requestId] = _msgSender();
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        for (uint256 i = 0; i < randomWords.length; i++) {
            uint256 newItemId = (randomWords[i] % totalSupply) + 1;
            _safeMint(receiving_addresses[requestId], newItemId);
            emit newNFTMinted(newItemId, receiving_addresses[requestId]);
        }
        delete receiving_addresses[requestId];
    }

    function mintToken(uint256 _quantity, bytes32[] calldata _merkleProof)
        public
        payable
    {
        require(step > 0 && step < 4, "No Mint step");
        require(_quantity <= 5, "Max 5 per transactions.");
        if (step == 1) {
            require(
                _mintedNFTs.current() + _quantity <= firstSaleMaxCnt,
                string(
                    abi.encodePacked(
                        (firstSaleMaxCnt - _mintedNFTs.current()).toString(),
                        " remaining for the first round."
                    )
                )
            );
            require(
                msg.value >= (_quantity * 0.15 ether),
                "Cannot pass cuz less price: step 1"
            );
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(
                MerkleProof.verify(_merkleProof, _merkleRootWhitelisted, leaf),
                "You are not Whitelisted."
            );
        }
        if (step == 2) {
            require(
                _mintedNFTs.current() + _quantity <= secondSaleMaxCnt,
                string(
                    abi.encodePacked(
                        (secondSaleMaxCnt - _mintedNFTs.current()).toString(),
                        " remaining for the second round."
                    )
                )
            );
            require(
                msg.value >= (_quantity * 0.25 ether),
                "Cannot pass cuz less price: step 2"
            );
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(
                MerkleProof.verify(_merkleProof, _merkleRootWhitelisted, leaf),
                "You are not Whitelisted."
            );
        }
        if (step == 3) {
            require(
                _mintedNFTs.current() + _quantity <= thirdSaleMaxCnt,
                string(
                    abi.encodePacked(
                        (thirdSaleMaxCnt - _mintedNFTs.current()).toString(),
                        " remaining for the third round."
                    )
                )
            );
            require(
                msg.value >= (_quantity * 0.3 ether),
                "Cannot pass cuz less price: step 3"
            );
        }

        for(uint256 i = _quantity; i > 0; i--) {
            _mintedNFTs.increment();
        }

        requestRandomWords(uint32(_quantity));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Royalty, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function royaltyInfo(
        uint256, /* tokenId */
        uint256 salePrice
    ) public view override returns (address receiver, uint256 royaltyAmount) {
        receiver = royalty_receiver;
        royaltyAmount = (royalty_amount * salePrice) / 10000;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function setBaseURI(string memory _newURI) public onlyDeveloper {
        baseURI = _newURI;
    }

    function setStep(uint8 _step) public onlyDeveloper {
        step = _step;
    }

    function setMerkleRoot(bytes32 _newRoot) public onlyDeveloper {
        _merkleRootWhitelisted = _newRoot;
    }

    /* this function can be used to:
     * - withdraw
     * - send refund to users in case something goes wrong with the Chainlink VRF function
     */
    function sendEthToAddr(uint256 _amount, address payable _to) external payable onlyOwner
    {
        require(
            _amount <= address(this).balance,
            "amount must be <= than balance."
        );
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function setRoyaltyReceiver(address _addr) public onlyOwner {
        royalty_receiver = _addr;
    }

    function setRoyaltyAmount(uint256 _amount) public onlyOwner {
        royalty_amount = _amount;
    }

    function setCallbackGasLimit(uint32 _limit) public onlyDeveloper {
        callbackGasLimit = _limit;
    }

    function setSubscriptionId(uint64 _id) public onlyDeveloper {
        s_subscriptionId = _id;
    }

    function setKeyHash(bytes32 _keyhash) public onlyDeveloper {
        keyHash = _keyhash;
    }

    function mintTo(uint256 _quantity, uint256[] memory _token_id, address _to) external onlyOwner {
        require(_quantity == _token_id.length, "must have same length");
        for(uint i = 0; i < _quantity; i++) {
            _safeMint(_to, _token_id[i]);
        }
    }
}