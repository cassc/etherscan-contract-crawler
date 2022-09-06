// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "./Administered.sol";

contract OnlyPass is ERC721A, Ownable {
    enum Stage {
        Paused,
        AllowList,
        Public
    }

    address public constant TEAM_ADDRESS = 0x684781121eE7A976ff63739Db8Cacda475Cffc2F;

    uint256 public constant MAX_PER_WALLET = 3;
    uint256 public constant AL_MAX_PER_WALLET = 2;
    uint256 public constant MAX_SUPPLY = 3690;

    uint256 public publicPrice = 0.02 ether;
    uint256 public allowListPrice = 0.015 ether;

    /// @dev 2000 comes from 1667 free mints allocated to AL phase, and an additional 333 to public.
    uint256 public freeMintsRemaining = 2000; // (1667 + 333);
    uint256 public remainingReserveMints = 50;

    Stage public stage;
    string public baseTokenURI;

    constructor(address[] memory admins, string memory _baseTokenURI) ERC721A("OnlyPass", "OP") {
        baseTokenURI = _baseTokenURI;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "OP: EOA_ONLY");
        _;
    }

    modifier mintCompilance(uint256 _quantity) {
        require(_quantity > 0, "OP: MINT_QTY_GT_0");
        require(_totalMinted() + _quantity <= MAX_SUPPLY, "OP: MAX_SUPPLY_EXEECED");
        require(
            _numberMinted(msg.sender) + _quantity <=
                (stage == Stage.AllowList ? AL_MAX_PER_WALLET : MAX_PER_WALLET),
            "OP: MAX_PER_WALLET_EXEECED"
        );
        _;
    }

    function allowListMint(uint256 _quantity)
        external
        payable
        callerIsUser
        mintCompilance(_quantity)
    {
        require(stage == Stage.AllowList, "OP:AL INVALID_STAGE");
        require(_getAux(msg.sender) > 0, "OP:AL UNAUTHORIZED_CALLER");
        // modifier checks guarantee the invariant: _quantity > 0 && _quantity <= MAX_PER_WALLET
        if (_numberMinted(msg.sender) == 0) {
            freeMintsRemaining--;
        } else {
            require((_quantity - 1) * allowListPrice <= msg.value, "OP:AL INSUFFICIENT_PAYMENT");
        }
        _mint(msg.sender, _quantity);
    }

    function publicSaleMint(uint256 _quantity)
        external
        payable
        callerIsUser
        mintCompilance(_quantity)
    {
        require(stage == Stage.Public, "OP:PUB INVALID_STAGE");
        // modifier checks guarantee the invariant: _quantity > 0 && _quantity <= MAX_PER_WALLET
        if (_shouldApplyFreeClaim(msg.sender)) {
            freeMintsRemaining--;
            require((_quantity - 1) * publicPrice <= msg.value, "OP:PUB INSUFFICIENT_PAYMENT");
        } else {
            require((_quantity * publicPrice) <= msg.value, "OP:PUB INSUFFICIENT_PAYMENT");
        }
        _mint(msg.sender, _quantity);
    }

    function isAllowListed(address _address) public view returns (bool) {
        return _getAux(_address) > 0;
    }

    // EXTERNAL ADMIN ONLY FUNCTIONS ===============================================
    // =============================================================================

    function editAllowList(address[] calldata toAdd, address[] calldata toRemove)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < toAdd.length; i++) {
            _setAux(toAdd[i], 1);
        }
        for (uint256 i = 0; i < toRemove.length; i++) {
            _setAux(toRemove[i], 0);
        }
    }

    function reserveMint(address to, uint256 _quantity)
        external
        onlyOwner
        mintCompilance(_quantity)
    {
        require(_quantity <= remainingReserveMints, "OP:RESERVE INVALID_QTY");
        remainingReserveMints -= _quantity;
        _mint(to, _quantity);
    }

    function updatePrice(uint256 _alPrice, uint256 _publicPrice) public onlyOwner {
        publicPrice = _publicPrice;
        allowListPrice = _alPrice;
    }

    function setStage(Stage _state) external onlyOwner {
        stage = _state;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(TEAM_ADDRESS).call{value: address(this).balance}("");
        require(success, "OP: ETH_TRANSFER_FAILED");
    }

    function setFreeMintsRemaining(uint256 _freeMintsRemaining) external onlyOwner {
        freeMintsRemaining = _freeMintsRemaining;
    }

    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    // INTERNAL ====================================================================
    // =============================================================================

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _shouldApplyFreeClaim(address addr) private view returns (bool) {
        return _numberMinted(addr) == 0 && freeMintsRemaining > 0;
    }
}