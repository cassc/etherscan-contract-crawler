// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
/*
            @@@@@@        @@@@@@@@@@@@@@@   @@@@@@.    @@@@@@  /@@@@@&     @@@@@@  @@@@@@*
        @@@@@@@@@@@@@.   @@@@@@@@@@@@@@@& /@@@@@@@.   @@@@@@@ [email protected]@@@@@    @@@@@@@  %@@@@@@ 
     [email protected]@@@@@@@@@@@@@@@  #@@@@@@@@@@@@@@@ [email protected]@@@@@@@@  #@@@@@@  @@@@@@.  %@@@@@&   /@@@@@@  
     @@@@@@    @@@@@@. *@@@@@@           @@@@@@@@@@  @@@@@@  @@@@@@/ @@@@@@@    [email protected]@@@@@   
    @@@@@@,            @@@@@@           @@@@@@@@@@@ @@@@@@* #@@@@@@*@@@@@@/     @@@@@@/   
   &@@@@@/ @@@@@@@@@  @@@@@@@@@@@@@@   &@@@@@@@@@@@@@@@@@% *@@@@@@@@@@@@@      @@@@@@@    
  (@@@@@% #@@@@@@@@  &@@@@@@@@@@@@@*   @@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@*      #@@@@@@     
 ,@@@@@@   /@@@@@@  (@@@@@@///////    @@@@@@*@@@@@@@@@@@  @@@@@@(@@@@@@@     [email protected]@@@@@      
 @@@@@@    @@@@@@, ,@@@@@@           @@@@@@& /@@@@@@@@@  &@@@@@@ @@@@@@@     @@@@@@       
@@@@@@@@&@@@@@@@@  @@@@@@@@@@@@@@@/ &@@@@@@  /@@@@@@@@@ (@@@@@@   @@@@@@    @@@@@@@       
(@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@& *@@@@@@   /@@@@@@@@ ,@@@@@@    @@@@@@   %@@@@@@        
  /@@@@@@@&@@@@  %@@@@@@@@@@@@@@@  @@@@@@     @@@@@@@  @@@@@@     @@@@@@  (@@@@@@         
 */

/**
 * @title A bidding contract with erc721a token implementation
 * @author @inetdave (Void Zero Labs)
 * @notice Bidding contract developed with mechanisms for airdrops, refunds, private and public mint
 * @dev All function calls have been tested.
 * v.01.00.00
 */

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./GenkiBid.sol";

contract GenkiBidMint is GenkiBid, AccessControl, ERC2981 {
    bytes32 public constant SUPPORT_ROLE = keccak256("SUPPORT");

    address private _royaltiesReceiver;
    uint256 private _royaltiesPercentage;

    mapping(address => bool) public winningBidders;

    constructor() {
        // set up roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SUPPORT_ROLE, msg.sender);
    }

    // ERC165
    /**
     * @dev See {GenkiBase-_setContractState} for implementation.
     */
    function setContractState(ContractState _contractState)
        external
        onlyRole(SUPPORT_ROLE)
    {
        _setContractState(_contractState);
    }

    /**
     * @dev See {GenkiBase-_setPrices} for implementation.
     */
    function setPrices(
        uint256 _price,
        uint256 _discountedPrice,
        uint256 _OGPrice
    ) external onlyRole(SUPPORT_ROLE) {
        _setPrices(_price, _discountedPrice, _OGPrice);
    }

    /**
     * @dev set the max bid supploy on contract GenkiBase
     */
    function setMaxBidSupply(uint256 _maxBidSupply)
        external
        onlyRole(SUPPORT_ROLE)
    {
        maxBidSupply = _maxBidSupply;
    }

    /** 
    * @notice set winning addresses
    * @dev this will be used to run processbidders
    */
    function setWinningBids(address[] calldata _addresses)
        external
        onlyRole(SUPPORT_ROLE)
    {
        for (uint256 i = 0; i < _addresses.length; ) {
            Bidder storage bidder = bidderData[_addresses[i]];
            bidder.winningBid = true;
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice process bidders from a list of addresses
     * @dev after bidding is stopped and price is set. run to handle the airdrop and refund from a array of addresses
     * calldata is used
     * @param _addresses adresses to process
     */
    function processBidders(address[] calldata _addresses)
        external
        onlyRole(SUPPORT_ROLE)
    {
        require(price != 0, "Price missing");
        for (uint256 i = 0; i < _addresses.length; ) {
            _processBidder(_addresses[i]);
            unchecked {
                ++i;
            }
        }
    }    
    /**
     * @notice incase there is a failure on processBidders use this to handle
     * @dev this will update the refund claimed to true
     * @param _addresses adresses to process
     */
    function processBiddersRefunds(address[] calldata _addresses, uint256[] calldata _refundValues)
        external
        onlyRole(SUPPORT_ROLE)
    {
        require(_addresses.length == _refundValues.length, "Mismatched arrays");
        for (uint256 i = 0; i < _addresses.length; ) {
            _processBidderRefunds(_addresses[i], _refundValues[i]);
            unchecked {
                ++i;
            }
        }
    }

    // ERC165
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981, AccessControl)
        returns (bool)
    {
        return ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }


    // ERC2981
    /**
     * @dev See {ERC2981-_setDefaultRoyalty}.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyRole(SUPPORT_ROLE)
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    //GENKIMINT

    /**
     * @dev see {GenkiMint - baseURI}
     */
    function setBaseURI(string memory _newBaseURI)
        public
        onlyRole(SUPPORT_ROLE)
    {
        baseURI = _newBaseURI;
    }

    /**
     * @dev see {GenkiMint - merkleRoot}
     *
     */
    function setMerkleRoots(bytes32 _merkleRootWL, bytes32 _merkleRootOG)
        external
        onlyOwner
    {
        merkleRootWL = _merkleRootWL;
        merkleRootOG = _merkleRootOG;
    }

    /**
     * @dev handles minting from airdrop.
     * @param _addresses address array to mint tokens to.
     * @param _numbers numbers of tokens to mint.
     * @dev state of contract should not be paused. if total number of airdrop tokens exceed MAX_SUPPLY the whole txn will fail.
     */
    function airdropMintBatch(
        address[] calldata _addresses,
        uint256[] calldata _numbers
    ) external onlyRole(SUPPORT_ROLE) {
        require(_addresses.length == _numbers.length, "Mismatched arrays");
        for (uint256 i; i < _addresses.length; ) {
            _airdropMint(_addresses[i], _numbers[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice after bidding and airdrop open the whitelist mint.
     * wl mint should use the discounted price
     * @param _quantity number of tokens users would like to mint.
     * @param _merkleProof passed in by user to validate the node
     */

    function whiteListMint(uint256 _quantity, bytes32[] calldata _merkleProof)
        external
        payable
        nonReentrant
    {
        address sender = _msgSenderERC721A();

        require(discountedPrice != 0, "Discount missing");
        require(OGPrice != 0, "OG Price missing");
        require(
            contractState == ContractState.WHITELIST,
            "Private mint closed"
        );
        require(
            _quantity <= MAX_PER_PRIVATE_WALLET - _alreadyMinted[sender],
            "Wallet max exceeded"
        );

        if (_verifyOG(_merkleProof, sender)) {
            _alreadyMinted[sender] += _quantity;
            _internalMint(sender, _quantity, OGPrice);
        } else if (_verifyWL(_merkleProof, sender)) {
            _alreadyMinted[sender] += _quantity;
            _internalMint(sender, _quantity, discountedPrice);
        } else {
            revert("Not in whitelist");
        }
    }

    function publicMint(uint256 _quantity)
        external
        payable
        nonReentrant
    {
        require(price != 0, "Price missing");
        require(contractState == ContractState.PUBLIC, "Public mint closed");
        require(_quantity <= MAX_PER_TX, "Transaction max exceeded");

        _internalMint(msg.sender, _quantity, price);
    }

    /**
     * @notice tokens to reserve mint.
     * @param _quantity number of tokens to reserve mint.
     */
    function reserveMint(uint256 _quantity) external onlyRole(SUPPORT_ROLE) {
        _safeMint(msg.sender, _quantity);
    }

    function withdraw() public onlyRole(SUPPORT_ROLE) {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");

        //Operator * not compatible with types uint256.
        payable(VOID_ZERO).transfer((balance * 175) / 1000);

        if (!_hasPaidLumpSum) {
            require(balance >= 50, "Insufficient Lump Sum");
            payable(ANGEL_INVESTOR).transfer(50 ether);
            _hasPaidLumpSum = true;
        }
        payable(OWNER).transfer(address(this).balance);
    }


    //OS Operator Filter
    function repeatRegistration() public {
        _registerForOperatorFiltering();
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return operatorFilteringEnabled;
    }
}