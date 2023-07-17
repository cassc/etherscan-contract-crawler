// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// ********************#********#***#********#*#****#********************
// *******************#:         *%+          =*    [email protected]#******************
// *******************#.         [email protected]=    ..    -#....:@%******************
// *******************#.   *@=   [email protected]=    %@    -%++++*@#******************
// *******************#.   :=:   [email protected]=    %@    -*    [email protected]%******************
// *******************#.        -#@=    %@    -*    [email protected]%******************
// *******************#.   +#=    *=    %@    -*    [email protected]%******************
// *******************#.   *@+    +=    %@    -*    [email protected]%******************
// *******************#.   .-.    +=          -*    [email protected]%******************
// *******************#.          *+          =*    [email protected]%******************
// ********************#%%%%%%%%%@@%#%%%%%%%%%@%#%%%%@#******************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// ************************************************************@nftchef**

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/ERC721A/contracts/ERC721A.sol";
import "lib/operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "lib/openzeppelin-contracts/contracts/security/Pausable.sol";
import "lib/openzeppelin-contracts/contracts/finance/PaymentSplitter.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "lib/openzeppelin-contracts/contracts/token/common/ERC2981.sol";

error InsufficientFunds();
error NotAllowed();
error AlreadyClaimed();
error MissingQuantity();
error ExceedsSupply();
error ExceedsLimit();
error incorrectPhase();
error PresaleOnly();

interface IBQ {
    function mint(address _to, uint256 _quantity) external;
}

contract Boi is
    ERC721A,
    ERC2981,
    Ownable,
    DefaultOperatorFilterer,
    Pausable,
    PaymentSplitter
{
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public B_LIMIT = 1;
    uint256 public LIMIT = 4;
    uint256 public B_PRICE;
    uint256 public PRICE;
    uint256 public SUPPLY = 5000;
    bool public revealed = false;
    IBQ internal _q;
    enum PHASE {
        Genesis,
        B_list,
        Public
    }

    // Starts at PHASE.Genesis
    PHASE public CURRENT_PHASE;

    mapping(address => bool) public claimed_genesis;
    mapping(address => uint256) public mintBalances;
    mapping(address => uint256) public blistBalances;

    string public baseURI;
    address[] internal TEAM;
    address internal _SIGNER;

    constructor(
        string memory _name,
        string memory _ticker,
        string memory _uri,
        address[] memory _payees,
        uint256[] memory _shares,
        address royaltyReceiver
    ) ERC721A(_name, _ticker) PaymentSplitter(_payees, _shares) {
        TEAM = _payees;
        baseURI = _uri;
        _pause();
        _setDefaultRoyalty(royaltyReceiver, 420);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    // quantity is equal to the # of genesis tokens held at time of the snapshot
    function genesisClaim(
        uint256 _quantity,
        bytes32 _hash,
        bytes memory _signature
    ) external whenNotPaused {
        if (CURRENT_PHASE != PHASE.Genesis) {
            revert incorrectPhase();
        }
        if (claimed_genesis[msg.sender] == true) {
            revert AlreadyClaimed();
        }
        if (!checkHash(_hash, _signature, _SIGNER, _quantity)) {
            revert NotAllowed();
        }
        claimed_genesis[msg.sender] = true;
        mint(_quantity);
        // ??????
        _q.mint(msg.sender, _quantity);
    }

    function blistPurchase(
        uint256 _quantity,
        bytes32 _hash,
        bytes memory _signature
    ) external payable whenNotPaused {
        if (!checkHash(_hash, _signature, _SIGNER, _quantity)) {
            revert NotAllowed();
        }

        if (_quantity + blistBalances[msg.sender] > B_LIMIT) {
            revert ExceedsLimit();
        }

        if (msg.value < B_PRICE * _quantity) {
            revert InsufficientFunds();
        }
        blistBalances[msg.sender] += _quantity;
        mint(_quantity);
        // ??????????????????
        _q.mint(msg.sender, _quantity);
    }

    function purchase(uint256 _quantity) external payable whenNotPaused {
        if (CURRENT_PHASE != PHASE.Public) {
            revert incorrectPhase();
        }

        if (msg.value < PRICE * _quantity) {
            revert InsufficientFunds();
        }
        if (_quantity > LIMIT) {
            revert ExceedsLimit();
        }
        if (_quantity + mintBalances[msg.sender] > LIMIT) {
            revert ExceedsLimit();
        }

        mintBalances[msg.sender] += _quantity;
        mint(_quantity);
    }

    function mint(uint256 _quantity) internal {
        if (_quantity < 1) {
            revert MissingQuantity();
        }
        if (totalSupply() + _quantity > SUPPLY) {
            revert ExceedsSupply();
        }

        _mint(msg.sender, _quantity);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_exists(tokenId), '"ERC721Metadata: tokenId does not exist"');
        if (revealed) {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        } else {
            return baseURI;
        }
    }

    function airdrop(address[] calldata _wallets) external onlyOwner {
        uint256 wallets = _wallets.length;
        if (wallets + totalSupply() > SUPPLY) {
            revert ExceedsSupply();
        }

        for (uint256 i = 0; i < wallets; i++) {
            if (_wallets[i] != address(0)) {
                _safeMint(_wallets[i], 1);
            }
        }
    }

    function airdropMany(
        address _wallet,
        uint256 _quantity
    ) external onlyOwner {
        if (_quantity + totalSupply() > SUPPLY) {
            revert ExceedsSupply();
        }

        _safeMint(_wallet, _quantity);
    }

    function senderMessageHash(
        uint256 _quantity
    ) internal view returns (bytes32) {
        bytes32 message = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(address(this), msg.sender, _quantity)
                )
            )
        );
        return message;
    }

    function checkHash(
        bytes32 _hash,
        bytes memory signature,
        address _account,
        uint256 _quantity
    ) internal view returns (bool) {
        bytes32 senderHash = senderMessageHash(_quantity);
        if (senderHash != _hash) {
            return false;
        }
        return _hash.recover(signature) == _account;
    }

    function setSigner(address _address) external onlyOwner {
        _SIGNER = _address;
    }

    function setPaused(bool _state) external onlyOwner {
        _state ? _pause() : _unpause();
    }

    function setPhase(uint8 _phase) external onlyOwner {
        CURRENT_PHASE = PHASE(_phase);
    }

    function setBaseURI(string memory _URI, bool _reveal) external onlyOwner {
        baseURI = _URI;
        revealed = _reveal;
    }

    function updatePrices(uint256 _price, uint256 _bprice) external onlyOwner {
        PRICE = _price;
        B_PRICE = _bprice;
    }

    function updateLimits(uint256 _limit, uint256 _blimit) external onlyOwner {
        LIMIT = _limit;
        B_LIMIT = _blimit;
    }

    function setQContract(IBQ _address) external onlyOwner {
        _q = _address;
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function modifyClaimStatus(address _user, bool _state) external onlyOwner {
        claimed_genesis[_user] = _state;
    }

    function withdraw() external onlyOwner {
        for (uint256 i = 0; i < TEAM.length; i++) {
            release(payable(TEAM[i]));
        }
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
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
}