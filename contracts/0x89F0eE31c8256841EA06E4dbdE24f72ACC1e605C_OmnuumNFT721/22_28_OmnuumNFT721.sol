// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import '../utils/OwnableUpgradeable.sol';
import './SenderVerifier.sol';
import './OmnuumMintManager.sol';
import './OmnuumCAManager.sol';
import './TicketManager.sol';
import './OmnuumWallet.sol';
import './OperatorFilterRegistry/DefaultOperatorFiltererUpgradeable.sol';

/// @title OmnuumNFT721 - NFT contract that implements the ERC721 standard
/// @author Omnuum Dev Team - <[email protected]>
/*
                       *$#_(xz&[email protected]@B&zx(_:`.
                  ."}*$%WMM8$$$$$$$$$$$$$$*}".
                ,{}:`.       .'^;[[email protected]$$$$$$$$$$t,
            ;1.          `I1&$$$$$$8u)!,iv$$$$$$$$8;
          .x~        ^Ii,`'''`^:_t%$$$$$B|_(@$$$$$$$x.
         '&|       ":.             '!u$$$$$M_1$$$$$$$&'
        '8$'     .1'                  '?B$$$$u,x$$$$$$8'
        v$8     '&'                     .-$$$$%`i$$$$$$v
       j$$$.   i$c                          t$$$- `B$$$$j
       B$$$~   r$$.                          u$$z  "$$$$%
       v$$$$z. ?$$$-                          c$)   `$$$v
       .&$$$$$W`"$$$$,                       .B:     @$&.
        ^$$$$$$$_"&$$$$v,                    )"     '$$^
         ,$$$$$$$Wi{$$$$$&?`               `!.      [$,
          `&$$$$$$$*_?M$$$$$Bt>"'.     .^I:'       ,&`
           .1$$$$$$$$%]I!|#$$$$$$$$%8z\i`         +1.
             `/$$$$$$$$$M?^.'`^""^`'           .;[`
                  `_v$$$$$$$$$$$$B*xt|(\fu&v_`
                     .`I[j#@[email protected]#j}I*/

contract OmnuumNFT721 is ERC721Upgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable, DefaultOperatorFiltererUpgradeable {
    using AddressUpgradeable for address;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    OmnuumCAManager private caManager;
    OmnuumMintManager private mintManager;

    // @notice OMNUUM deployer address
    address private omnuumSigner;

    /// @notice Maximum supply limit that can be minted
    uint32 public maxSupply;

    /// @notice Revealed or not
    /// @dev The number of reveal is limited to once per NFT contract controlled by RevealManager contract
    bool public isRevealed;
    string public baseURI;

    event BaseURIChanged(address indexed nftContract, string baseURI);
    event MintFeePaid(address indexed nftContract, address indexed payer, uint256 profit, uint256 mintFee);
    event BalanceTransferred(address indexed receiver, uint256 value);
    event EtherReceived(address indexed sender, uint256 value);
    event Revealed(address indexed nftContract);

    /// @notice constructor function for upgradeable
    /// @param _caManagerAddress ca manager address
    /// @param _omnuumSigner Address of Omnuum signer for creating and verifying off-chain ECDSA signature
    /// @param _maxSupply max amount can be minted
    /// @param _coverBaseURI metadata uri for before reveal
    /// @param _prjOwner project owner address to transfer ownership
    /// @param _name NFT name
    /// @param _symbol NFT symbol
    function initialize(
        address _caManagerAddress,
        address _omnuumSigner,
        uint32 _maxSupply,
        string calldata _coverBaseURI,
        address _prjOwner,
        string calldata _name,
        string calldata _symbol
    ) public initializer {
        /// @custom:error (AE1) - Zero address not acceptable
        require(_caManagerAddress != address(0), 'AE1');
        require(_prjOwner != address(0), 'AE1');

        __ERC721_init(_name, _symbol);
        __ReentrancyGuard_init();
        __Ownable_init();
        __DefaultOperatorFilterer_init();

        maxSupply = _maxSupply;
        omnuumSigner = _omnuumSigner;
        baseURI = _coverBaseURI;

        caManager = OmnuumCAManager(_caManagerAddress);
        mintManager = OmnuumMintManager(caManager.getContract('MINTMANAGER'));
    }

    /// @dev For opensea filterRegistry
    function initFilterRegistryAfterDeploy() external onlyOwner {
        __DefaultOperatorFilterer();
    }

    /// @dev See {ERC721Upgradeable}.
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// @notice Allows an owner to change base URI.
    function changeBaseURI(string calldata baseURI_) public onlyOwner {
        baseURI = baseURI_;

        emit BaseURIChanged(address(this), baseURI_);
    }

    /// @notice Returns the total amount of tokens supplied in the contract.
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /// @notice public minting function
    /// @param _quantity minting quantity
    /// @param _groupId public minting schedule id
    /// @param _payload payload for authenticate that mint call happen through omnuum server to guarantee exact schedule time
    function publicMint(
        uint32 _quantity,
        uint256 _groupId,
        SenderVerifier.Payload calldata _payload
    ) external payable nonReentrant {
        /// @custom:error (MT9) - Minter cannot be CA
        require(!msg.sender.isContract(), 'MT9');

        SenderVerifier(caManager.getContract('VERIFIER')).verify(omnuumSigner, msg.sender, 'MINT', _groupId, _payload);
        mintManager.preparePublicMint(_groupId, _quantity, msg.value, msg.sender);

        payMintFee(_quantity);
        mintLoop(msg.sender, _quantity);
    }

    /// @notice ticket minting function
    /// @param _quantity minting quantity
    /// @param _ticket ticket struct which proves authority to mint
    /// @param _payload payload for authenticate that mint call happen through omnuum server to guarantee exact schedule time
    function ticketMint(
        uint32 _quantity,
        TicketManager.Ticket calldata _ticket,
        SenderVerifier.Payload calldata _payload
    ) external payable nonReentrant {
        /// @custom:error (MT9) - Minter cannot be CA
        require(!msg.sender.isContract(), 'MT9');

        /// @custom:error (MT5) - Not enough money
        require(_ticket.price * _quantity <= msg.value, 'MT5');

        SenderVerifier(caManager.getContract('VERIFIER')).verify(omnuumSigner, msg.sender, 'TICKET', _ticket.groupId, _payload);
        TicketManager(caManager.getContract('TICKET')).useTicket(omnuumSigner, msg.sender, _quantity, _ticket);

        payMintFee(_quantity);
        mintLoop(msg.sender, _quantity);
    }

    /// @notice direct mint, neither public nor ticket
    /// @param _to mint destination address
    /// @param _quantity minting quantity
    function mintDirect(address _to, uint256 _quantity) external {
        /// @custom:error (OO3) - Only Omnuum or owner can change
        require(msg.sender == address(mintManager), 'OO3');
        mintLoop(_to, _quantity);
    }

    /// @notice minting utility function, manage token id
    /// @param _to mint destination address
    /// @param _quantity minting quantity
    function mintLoop(address _to, uint256 _quantity) internal {
        /// @custom:error (MT3) - Remaining token count is not enough
        require(_tokenIdCounter.current() + _quantity <= maxSupply, 'MT3');
        for (uint256 i = 0; i < _quantity; i++) {
            _tokenIdCounter.increment();
            _safeMint(_to, _tokenIdCounter.current());
        }
    }

    /// @notice transfer balance of the contract to address (project team member or else) including project owner him or herself
    /// @param _value The amount of value to transfer
    /// @param _to Receiver who receive the value
    function transferBalance(uint256 _value, address _to) external onlyOwner nonReentrant {
        /// @custom:error (NE4) - Insufficient balance
        require(_value <= address(this).balance, 'NE4');
        (bool withdrawn, ) = payable(_to).call{ value: _value }('');

        /// @custom:error (SE5) - Address: unable to send value, recipient may have reverted
        require(withdrawn, 'SE5');

        emit BalanceTransferred(_to, _value);
    }

    /// @notice a function to donate to support the project owner. Hooray~!
    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

    /// @notice send fee to omnuum wallet
    /// @param _quantity Mint quantity
    function payMintFee(uint256 _quantity) internal {
        uint8 rateDecimal = mintManager.rateDecimal();
        uint256 minFee = mintManager.minFee();
        uint256 feeRate = mintManager.getFeeRate(address(this));
        uint256 calculatedFee = (msg.value * feeRate) / 10**rateDecimal;
        uint256 minimumFee = _quantity * minFee;

        uint256 feePayment = calculatedFee > minimumFee ? calculatedFee : minimumFee;

        OmnuumWallet(payable(caManager.getContract('WALLET'))).mintFeePayment{ value: feePayment }(address(this));

        emit MintFeePaid(address(this), msg.sender, msg.value - feePayment, feePayment);
    }

    /// @notice can execute only once!!
    /// @dev update reveal flag and update base uri
    /// @param baseURI_ revealed metadata uri
    function setRevealed(string calldata baseURI_) external onlyOwner {
        /// @custom:error (SE6) - Already revealed
        require(!isRevealed, 'SE6');

        isRevealed = true;
        changeBaseURI(baseURI_);

        emit Revealed(address(this));
    }

    function burn(uint256 tokenId) public virtual {
        /// @custom:error (OO9) - Caller is not owner nor approved
        require(_isApprovedOrOwner(_msgSender(), tokenId), 'OO9');
        _burn(tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
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
}