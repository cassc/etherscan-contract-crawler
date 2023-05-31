// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MerkleProofOpt.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Emotons is ERC1155, Ownable, VRFConsumerBaseV2 {
    using Strings for uint256;

    uint8 _phase;

    uint256 _supply = 10000;
    uint256 _currentTokenId;
    uint256 _provenance;
    uint256 public _price = 0.03 ether;
    bytes32 public _root;
    string public _ipfsGateway = "https://ipfs.infura.io/ipfs/";
    string public _ipfsCid;
    mapping(uint256 => uint256) public _vouchersTracker;

    bytes32 public _secretLockKey;
    uint256 public _secretToken;
    string public _secretIpfsCid;

    uint64 _subscriptionId;
    VRFCoordinatorV2Interface _COORDINATOR;
    address _vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    bytes32 _keyHash =
        0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
    uint256[] public _randomWords;
    uint256 public _requestId;

    constructor(uint64 subscriptionId)
        ERC1155("")
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        _COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        _subscriptionId = subscriptionId;
    }

    function setIpfsGateway(string memory ipfsGateway) public onlyOwner {
        _ipfsGateway = ipfsGateway;
    }

    function setIpfsCid(string memory ipfsCid) public onlyOwner {
        _ipfsCid = ipfsCid;
    }

    function setSecretLockKey(bytes32 secretLockKey, uint256 secretToken)
        external
        onlyOwner
    {
        _secretLockKey = secretLockKey;
        _secretToken = secretToken;
    }

    function setPrice(uint256 price) external onlyOwner {
        _price = price;
    }

    function setRoot(bytes32 root) external onlyOwner {
        _root = root;
    }

    function setCurrentPhase(uint8 phase) external onlyOwner {
        _phase = phase;
    }

    function finalize(
        uint256 supply,
        uint256 provenance,
        uint32 gasLimit
    ) external onlyOwner {
        _supply = supply;
        _provenance = provenance;
        if (gasLimit > 0) {
            _requestId = _COORDINATOR.requestRandomWords(
                _keyHash,
                _subscriptionId,
                3,
                gasLimit,
                1
            );
        }
    }

    function withdraw(address to) external onlyOwner {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (tokenId == _secretToken) {
            return string(abi.encodePacked(_ipfsGateway, _secretIpfsCid));
        }
        return
            string(
                abi.encodePacked(
                    _ipfsGateway,
                    _ipfsCid,
                    "/",
                    tokenId.toString(),
                    ".json"
                )
            );
    }

    function mintPrivate(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyOwner {
        uint256 recipientLength = recipients.length;
        require(amounts.length == recipientLength, "Lengths mismatch");

        for (uint256 i = 0; i < recipientLength; ) {
            require(
                _currentTokenId + amounts[i] <= _supply,
                "Amount exceeds supply"
            );
            _mintAmount(amounts[i], recipients[i]);
            unchecked {
                i++;
            }
        }
    }

    function mintPreSale(bytes32 leaf, bytes32[] calldata proof)
        public
        payable
    {
        require(_phase == 1, "Pre-sale not open");

        (uint8 paid, uint8 free, uint16 index, address account) = _unpackleaf(
            leaf
        );
        uint256 amount = paid + free;

        require(
            MerkleProof.verify(proof, _root, keccak256(abi.encodePacked(leaf))),
            "Invalid proof"
        );
        require(amount > 0, "Invalid leaf");
        require(_currentTokenId + amount <= _supply, "Max supply reached");
        require(account == msg.sender, "You are not the owner");
        uint256 cluster;
        uint256 bitMask;
        uint256 voucherBitmap;
        unchecked {
            cluster = index >> 8;
            bitMask = 1 << (index % 256);
            voucherBitmap = _vouchersTracker[cluster];
            require(voucherBitmap & bitMask == 0, "Already claimed");
            require(_price * paid <= msg.value, "Not enough ether");
        }

        _vouchersTracker[cluster] = voucherBitmap | bitMask;

        if (amount == 1) {
            _mint(account, ++_currentTokenId, 1, "");
        } else {
            _mintAmount(amount, msg.sender);
        }
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 cluster = index >> 8;
        uint256 bitMask = 1 << (index % 256);
        uint256 voucherBitmap = _vouchersTracker[cluster];

        return voucherBitmap & bitMask != 0;
    }

    function mintSale(
        bytes32 leaf,
        bytes32[] calldata proof,
        uint256 amount
    ) public payable {
        require(_phase == 2, "Sale not open");

        require(_currentTokenId + amount <= _supply, "Amount exceeds supply");
        require(
            MerkleProof.verify(proof, _root, keccak256(abi.encodePacked(leaf))),
            "Invalid proof"
        );

        (uint8 paid, uint8 free, , address account) = _unpackleaf(leaf);

        require(account == msg.sender, "You are not the owner");
        require(paid + free == 0, "Invalid leaf");
        require(_price * amount <= msg.value, "Not enough ether");

        _mintAmount(amount, msg.sender);
    }

    function mintPublic(uint256 amount) public payable {
        require(_phase == 3, "Public sale not open");
        require(_currentTokenId + amount <= _supply, "Amount exceeds supply");
        require(_price * amount <= msg.value, "Not enough ether");
        _mintAmount(amount, msg.sender);
    }

    function mintPlaceholder(uint256 placeholderId) external onlyOwner {
        require(placeholderId > _supply, "Conflict with supply");
        _mint(msg.sender, placeholderId, 1, "");
    }

    function burnPlaceholder(uint256 placeholderId) external onlyOwner {
        require(placeholderId > _supply, "Conflict with supply");
        _burn(msg.sender, placeholderId, 1);
    }

    function _mintAmount(uint256 amount, address account) internal {
        uint256[] memory ids = new uint256[](amount);
        uint256[] memory amounts = new uint256[](amount);
        uint256 newCurrentTokenId = _currentTokenId;
        for (uint256 i = 0; i < amount; ) {
            unchecked {
                ids[i] = ++newCurrentTokenId;
                amounts[i] = 1;
                ++i;
            }
        }
        _currentTokenId = newCurrentTokenId;
        _mintBatch(account, ids, amounts, "");
    }

    function _unpackleaf(bytes32 leaf)
        internal
        pure
        returns (
            uint8 paid,
            uint8 free,
            uint16 index,
            address account
        )
    {
        paid = uint8(uint256(leaf) >> 248);
        free = uint8(uint256(leaf) >> 240);
        index = uint16(uint256(leaf) >> 224);
        account = address(uint160(uint256(leaf)));
    }

    function mintSecret(string calldata ipfsCid) public {
        require(
            _secretLockKey == keccak256(abi.encodePacked(ipfsCid)),
            "Wrong key"
        );

        _mint(msg.sender, _secretToken, 1, "");
        _secretIpfsCid = ipfsCid;
        _secretLockKey = 0;
    }

    // Randomness

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        _randomWords = randomWords;
    }
}