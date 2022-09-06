//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/[email protected]/utils/cryptography/MerkleProof.sol";



contract CosmicCollective is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant RESERVE_MAX = 658;
    uint256 public constant TOTAL_MAX = 1111;
    uint256 public constant MAX_SALE_QUANTITY = 4;
    uint256 public whitelistPrice = 0.069 ether;
    uint256 public whitelistCount;
    uint256 public HolderlistPrice = 0.09 ether;
    uint256 public reserveCount;
    mapping(address => uint256) public whitelistClaimed;
    mapping(address => uint256) public HolderlistClaimed;
    bytes32 private merkleRoot;
    uint256 public MutantHoldings = IERC721(0x44102Bd86bCcB4eFe8E90b4A4D5C4E43a895D22e).balanceOf(msg.sender);
    uint256 public holdingFetch;
    uint256 public DAPrice = 0.25 ether;
    mapping(address => uint256) public DAClaimed;
    uint32 public startTime;
    bool public saleActive;
    bool public whitelistActive;
    bool private whitelistEnded;
    bool public HolderlistActive;
    bool private HolderlistEnded;

    struct DAVariables {
        uint64 saleStartPrice;
        uint64 duration;
        uint64 interval;
        uint64 decreaseRate;
    }

    DAVariables public daVariables;

    string private baseURI;
    bool public revealed;

    address private paymentAddress;

    constructor() ERC721A("CosmicCollective", "COSMIC") {
        
    }

    /**
     * @notice not locked modifier for OG
     */
    modifier OGnotEnded() {
        require(!whitelistEnded, "WHITELIST_ENDED");
        _;
    }


    /**
     * @notice not locked modifier for Holders
     */
    modifier HoldernotEnded() {
        require(!HolderlistEnded, "HOLDERLIST_ENDED");
        _;
    }

    /**
     * @notice mint from OG whitelist
     * @dev must occur before public sale and holder sale
     */
    function mintOG(bytes32[] memory _merkleProof) external payable OGnotEnded {
        require(whitelistActive, "WHITELIST_INACTIVE");
     // require(whitelistCount + _quantity <= WHITELIST_MAX, "WHITELIST_MAXED");
        require(msg.value == whitelistPrice, "INCORRECT_ETH");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
        require(whitelistClaimed[msg.sender] + 1 <= 1, "OGLIST_MAXED");
        unchecked {
            whitelistClaimed[msg.sender] += 1;
        }
        _safeMint(msg.sender, 1);
    }

    /**
     * @notice mint from Holderlist
     * @dev must occur before public sale
     */
    function mintHolder(uint256 _quantity) external payable HoldernotEnded {
        if (MutantHoldings <= 4) {
            require(HolderlistClaimed[msg.sender] + _quantity <= 1, "HOLDERMINT_MAXED");
        }
        if (MutantHoldings <= 8) {
            require(HolderlistClaimed[msg.sender] + _quantity <= 2, "HOLDERMINT_MAXED");
        }
        if (MutantHoldings <= 12) {
            require(HolderlistClaimed[msg.sender] + _quantity <= 3, "HOLDERMINT_MAXED");
        }
        if (MutantHoldings > 12) {
            require(HolderlistClaimed[msg.sender] + _quantity <= 4, "HOLDERMINT_MAXED");
        }
        require(HolderlistActive, "HOLDERLIST_INACTIVE");
     // require(whitelistCount + _quantity <= WHITELIST_MAX, "WHITELIST_MAXED");
        require(MutantHoldings >= 1, "NOT_HOLDING");
        require(msg.value == HolderlistPrice * _quantity, "INCORRECT_ETH");

        unchecked {
            HolderlistClaimed[msg.sender] += _quantity;
            
        }
        _safeMint(msg.sender, _quantity);
    }

    /**
     * @notice buy from sale (dutch auction)
     * @dev must occur after Holderlist sale
     */
    function buy(uint256 _quantity) external payable {
        require(saleActive, "SALE_INACTIVE");
        require(tx.origin == msg.sender, "NOT_EOA");
        require(
            _numberMinted(msg.sender) + _quantity <= MAX_SALE_QUANTITY,
            "QUANTITY_MAXED"
        );
        require(
            (totalSupply() - reserveCount) + _quantity <=
                TOTAL_MAX - RESERVE_MAX,
            "SALE_MAXED"
        );
        uint256 mintCost;
        DAVariables memory _daVariables = daVariables;
        if (block.timestamp - startTime >= _daVariables.duration) {
            mintCost = DAPrice * _quantity;
        } else {

            uint256 steps = (block.timestamp - startTime) /
                _daVariables.interval;
                
            if (steps < 10) {
                mintCost =
                    (daVariables.saleStartPrice -
                        (steps * _daVariables.decreaseRate)) *
                    _quantity;
                require(msg.value >= mintCost, "INSUFFICIENT_ETH");
            } else {
                mintCost = 0;
            }           
            // uint256 steps = (block.timestamp - startTime) /
            //     _daVariables.interval;
            // mintCost =
            //     (daVariables.saleStartPrice -
            //         (steps * _daVariables.decreaseRate)) *
            //     _quantity;
        }
        require(DAClaimed[msg.sender] + _quantity <= 4, "DA_MAXED");
        unchecked {
            DAClaimed[msg.sender] += _quantity;
        }
        _safeMint(msg.sender, _quantity);

        // if (msg.value > mintCost) {
        //     payable(msg.sender).transfer(msg.value - mintCost);
        // }
    }

    /**
     * @notice release Airdrops and Treasury
     */
    function releaseAirdropsAndTreasury(address _account, uint256 _quantity)
        external
        onlyOwner
    {
        require(_quantity > 0, "INVALID_QUANTITY");
        require(reserveCount + _quantity <= RESERVE_MAX, "RESERVE_MAXED");
        reserveCount = reserveCount + _quantity;
        _safeMint(_account, _quantity);
    }

    /**
     * @notice return number of tokens minted by owner
     */
    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    /**
     * @notice return current sale price
     */
    function getCurrentPrice() external view returns (uint256) {
        if (!saleActive) {
            return DAPrice;
        }
        DAVariables memory _daVariables = daVariables;
        if (block.timestamp - startTime >= _daVariables.duration) {
            return DAPrice;
        } else {
            uint256 steps = (block.timestamp - startTime) /
                _daVariables.interval;
                
            if (steps < 10) {
                return daVariables.saleStartPrice -
                (steps * _daVariables.decreaseRate);
            } else {
                return 0;
            }
            // return
            //     daVariables.saleStartPrice -
            //     (steps * _daVariables.decreaseRate);
        }
    }
    /**
     * @notice return Mutant Holdings
     */
    // function getMutantHoldings(address owner) external non returns (uint256) {
    //     holdingFetch = IERC721(0xA6b98F9cBA02A45eEB53A1381546e45768A12464).balanceOf(owner);
    //     return holdingFetch;
    // }

    /**
     * @notice active OG whitelist
     */
    function activateWhitelist() external onlyOwner {
        !whitelistActive ? whitelistActive = true : whitelistActive = false;
    }

    /**
     * @notice active Holder sale
     */
    function activateHolderSale() external onlyOwner {
        whitelistActive = false;
        if (!whitelistEnded) whitelistEnded = true;
        !HolderlistActive ? HolderlistActive = true : HolderlistActive = false;
    }

    /**
     * @notice active sale
     */
    function activateSale() external onlyOwner {
        require(daVariables.saleStartPrice != 0, "SALE_VARIABLES_NOT_SET");
        if (!whitelistEnded) whitelistEnded = true;
        if (whitelistActive) whitelistActive = false;
        if (!HolderlistEnded) HolderlistEnded = true;
        if (HolderlistActive) HolderlistActive = false;
        if (startTime == 0) {
            startTime = uint32(block.timestamp);
        }
        !saleActive ? saleActive = true : saleActive = false;
    }

    /**
     * @notice set sale startTime
     */
    function setSaleVariables(
        uint32 _startTime,
        uint64 _saleStartPrice,
        uint64 _duration,
        uint64 _interval,
        uint64 _decreaseRate
    ) external onlyOwner {
        require(!saleActive);
        startTime = _startTime;
        daVariables = DAVariables({
            saleStartPrice: _saleStartPrice,
            duration: _duration,
            interval: _interval,
            decreaseRate: _decreaseRate
        });
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