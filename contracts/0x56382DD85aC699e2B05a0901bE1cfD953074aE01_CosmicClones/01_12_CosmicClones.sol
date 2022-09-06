//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract CosmicClones is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant maxSupply = 5555;
    uint256 public cost = 0.0099 ether;
    uint256 public reserveCount;
    uint256 public priorityAllow;
    mapping(address => uint256) public prioritylistFreeClaimed;
    mapping(address => uint256) public prioritylistPaidClaimed;
    mapping(address => uint256) public WLFreeClaimed;
    mapping(address => uint256) public WLPaidClaimed;
    mapping(address => uint256) public publicFreeClaimed;
    mapping(address => uint256) public publicPaidClaimed;
    bytes32 private merkleRoot;
    bool public publicActive;
    bool public prioritylistActive;
    bool private prioritylistEnded;
    bool public WLActive;
    bool private WLEnded;
    string private baseURI;
    bool public revealed;
    address private paymentAddress;

    constructor() ERC721A("Cosmic Clones", "COSMICCLONES") {
    }

    /**
     * @notice not locked modifier for OG
     */
    modifier PrioritynotEnded() {
        require(!prioritylistEnded, "PRIORITYLIST_ENDED");
        _;
    }


    /**
     * @notice not locked modifier for Holders
     */
    modifier WLNotEnded() {
        require(!WLEnded, "WL_ENDED");
        _;
    }

    function mintFreePriority(uint256 _quantity) external payable PrioritynotEnded {
        priorityAllow = getPriorityQuantity(msg.sender);
        uint256 s = totalSupply();
        require(s + _quantity <= maxSupply, "Cant go over supply");
        require(prioritylistActive, "PRIORITYLIST_INACTIVE");
        require(prioritylistFreeClaimed[msg.sender] + _quantity <= priorityAllow, "PRIORITYLISTFREE_MAXED");
        unchecked {
            prioritylistFreeClaimed[msg.sender] += _quantity;
        }
        _safeMint(msg.sender, _quantity);
    }

    /**
     * @notice paid mint from priority whitelist
     * @dev must occur before public sale and holder sale
     */
    function mintPaidPriority(uint256 _quantity) external payable PrioritynotEnded {
        priorityAllow = getPriorityQuantity(msg.sender);
        uint256 s = totalSupply();
        require(s + _quantity <= maxSupply, "Cant go over supply");
        require(prioritylistActive, "PRIORITYLIST_INACTIVE");
        require(prioritylistPaidClaimed[msg.sender] + _quantity <= priorityAllow, "PRIORITYLISTPUBLIC_MAXED");
        require(msg.value >= cost, "INCORRECT_ETH");
        unchecked {
            prioritylistPaidClaimed[msg.sender] += _quantity;
        }
        _safeMint(msg.sender, _quantity);
    }

    /**
     * @notice mint from WL
     * @dev must occur before public sale
     */
    function mintFreeWL(bytes32[] memory _merkleProof) external payable WLNotEnded {
        uint256 s = totalSupply();
        require(s + 1 <= maxSupply, "Cant go over supply");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
        require(WLActive, "WL_INACTIVE");
        require(s + 1 <= maxSupply, "Cant go over supply");
        require(WLFreeClaimed[msg.sender] + 1 <= 1, "WLFREE_MAXED");
        unchecked {
            WLFreeClaimed[msg.sender] += 1;
            
        }
        _safeMint(msg.sender, 1);
    }

    /**
     * @notice mint from WL
     * @dev must occur before public sale
     */
    function mintPaidWL(bytes32[] memory _merkleProof) external payable WLNotEnded {
        uint256 s = totalSupply();
        require(s + 1 <= maxSupply, "Cant go over supply");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
        require(WLActive, "WL_INACTIVE");
        require(msg.value >= cost, "INCORRECT_ETH");
        require(WLPaidClaimed[msg.sender] + 1 <= 1, "WLPAID_MAXED");

        unchecked {
            WLPaidClaimed[msg.sender] += 1;
            
        }
        _safeMint(msg.sender, 1);
    }

    /**
     * @notice mint Paid Public
     * @dev must occur before public sale
     */
    function mintPaidPublic() external payable {
        uint256 s = totalSupply();
        require(s + 1 <= maxSupply, "Cant go over supply");
        require(publicActive, "PUBLIC_INACTIVE");
        require(msg.value >= cost, "INCORRECT_ETH");
        require(publicPaidClaimed[msg.sender] + 1 <= 1, "PUBLICPAID_MAXED");

        unchecked {
            publicPaidClaimed[msg.sender] += 1;
            
        }
        _safeMint(msg.sender, 1);
    }

    /**
     * @notice mint Free Public
     * @dev must occur before public sale
     */
    function mintFreePublic() external payable {
        uint256 s = totalSupply();
        require(s + 1 <= maxSupply, "Cant go over supply");
        require(publicActive, "PUBLIC_INACTIVE");
        require(publicFreeClaimed[msg.sender] + 1 <= 1, "PUBLICFREE_MAXED");

        unchecked {
            publicFreeClaimed[msg.sender] += 1;
            
        }
        _safeMint(msg.sender, 1);
    }


    /**
     * @notice release Airdrops and Treasury
     */
    function releaseAirdropsAndTreasury(address _account, uint256 _quantity)
        external
        onlyOwner
    {
        uint256 s = totalSupply();
        require(s + _quantity <= maxSupply, "Cant go over supply");
        require(_quantity > 0, "INVALID_QUANTITY");
        _safeMint(_account, _quantity);
    }

    /**
     * @notice return number of tokens minted by owner
     */
    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }


    /**
     * @notice active OG whitelist
     */
    function activatePrioritylist() external onlyOwner {
        !prioritylistActive ? prioritylistActive = true : prioritylistActive = false;
    }

    /**
     * @notice active Holder sale
     */
    function activateWLSale() external onlyOwner {
        prioritylistActive = false;
        if (!prioritylistEnded) prioritylistEnded = true;
        !WLActive ? WLActive = true : WLActive = false;
    }

    /**
     * @notice active sale
     */
    function activatePublicSale() external onlyOwner {
        if (!prioritylistEnded) prioritylistEnded = true;
        if (prioritylistActive) prioritylistActive = false;
        if (!WLEnded) WLEnded = true;
        if (WLActive) WLActive = false;
        !publicActive ? publicActive = true : publicActive = false;
    }

    /**
     * @notice set base URI
     */
    function setBaseURI(string calldata _baseURI, bool reveal) external onlyOwner {
        if (!revealed && reveal) revealed = reveal; 
        baseURI = _baseURI;
    }

    /**
     * @notice set payment address
     */
    function setPaymentAddress(address _paymentAddress) external onlyOwner {
        paymentAddress = _paymentAddress;
    }

    /**
     * @notice transfer funds
     */
    function transferFunds() external onlyOwner {
        (bool success, ) = payable(paymentAddress).call{
            value: address(this).balance
        }("");
        require(success, "TRANSFER_FAILED");
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice token URI
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Cannot query non-existent token");
        if (revealed) {
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
        } else {
            return baseURI;
        }
    }
}