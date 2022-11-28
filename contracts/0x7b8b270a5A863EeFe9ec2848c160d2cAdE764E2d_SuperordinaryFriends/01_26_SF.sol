//SPDX-License-Identifier: Unlicense
// Creator: Pixel8 Labs
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/finance/PaymentSplitter.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './lib/ERC721Base.sol';
import './lib/Signature.sol';

contract SuperordinaryFriends is
    ERC721Base,
    AccessControl,
    Pausable,
    ReentrancyGuard,
    Ownable
{
    uint256 public maxPerTx = 20;

    enum Phases {
        CLOSED,
        OGLIST,
        WHITELIST,
        WAITLIST,
        PUBLIC
    }
    Phases public phase = Phases.CLOSED;
    mapping(Phases => uint256) public price;
    mapping(Phases => address) public signer;

    constructor(
        address royaltyReceiver,
        uint96 royaltyFraction,
        string memory _tokenURI
    )
        ERC721Base(
            _tokenURI,
            'Superordinary Friends',
            'SF',
            2500,
            royaltyReceiver,
            royaltyFraction
        )
        Ownable()
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        price[Phases.OGLIST] = 0.048 ether;
        price[Phases.WHITELIST] = 0.048 ether;
        price[Phases.WAITLIST] = 0.048 ether;
        price[Phases.PUBLIC] = 0.048 ether;

        _transferOwnership(0x50781806F5267e96cD0D4693894dB8d4223BDe7F);
        _safeMint(0x50781806F5267e96cD0D4693894dB8d4223BDe7F, 150);
    }

    modifier canMint(uint256 amount, uint256 p) {
        uint256 supply = totalSupply();
        require(msg.value == p * amount, 'insufficient fund');
        require(supply + amount <= MAX_SUPPLY, 'exceed max supply');
        require(tx.origin == msg.sender, 'invalid source');
        _;
    }

    function mint(uint256 amount)
        external
        payable
        canMint(amount, price[Phases.PUBLIC])
        whenNotPaused
        nonReentrant
    {
        require(phase == Phases.PUBLIC, 'public mint is not open');
        require(amount <= maxPerTx, "amount can't exceed 20");

        _safeMint(msg.sender, amount);
    }

    function ogMint(
        uint256 amount,
        uint256 maxAmount,
        bytes memory signature
    )
        external
        payable
        canMint(amount, price[Phases.OGLIST])
        whenNotPaused
        nonReentrant
    {
        require(phase == Phases.OGLIST, 'og mint is not open');

        _verifyMint(amount, maxAmount, signature, signer[Phases.OGLIST]);
        _safeMint(msg.sender, amount);
    }

    function whitelistMint(
        uint256 amount,
        uint256 maxAmount,
        bytes memory signature
    )
        external
        payable
        canMint(amount, price[Phases.WHITELIST])
        whenNotPaused
        nonReentrant
    {
        require(phase == Phases.WHITELIST, 'whitelist mint is not open');

        _verifyMint(amount, maxAmount, signature, signer[Phases.WHITELIST]);
        _safeMint(msg.sender, amount);
    }

    function waitlistMint(
        uint256 amount,
        uint256 maxAmount,
        bytes memory signature
    )
        external
        payable
        canMint(amount, price[Phases.WAITLIST])
        whenNotPaused
        nonReentrant
    {
        require(phase == Phases.WAITLIST, 'waitlist mint is not open');

        _verifyMint(amount, maxAmount, signature, signer[Phases.WAITLIST]);
        _safeMint(msg.sender, amount);
    }

    function _verifyMint(
        uint256 amount,
        uint256 maxAmount,
        bytes memory signature,
        address _signer
    ) internal {
        uint64 aux = _getAux(msg.sender);
        require(aux + amount <= maxAmount, 'exceeded max per wallet');
        require(
            Signature.verify(maxAmount, msg.sender, signature) == _signer,
            'invalid signature'
        );
        _setAux(msg.sender, aux + uint64(amount));
    }

    function claimed(address target) external view returns (uint256) {
        return _getAux(target);
    }

    function airdrop(address wallet, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 supply = totalSupply();
        require(supply + amount <= MAX_SUPPLY, 'exceed max supply');
        _safeMint(wallet, amount);
    }

    function airdrops(address[] calldata wallet, uint256[] calldata amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 supply = totalSupply();
        require(wallet.length == amount.length, 'length mismatch');
        for (uint256 i = 0; i < wallet.length; i++) {
            require(supply + amount[i] <= MAX_SUPPLY, 'exceed max supply');
            _safeMint(wallet[i], amount[i]);
        }
    }

    // Minting fee
    function setPrice(Phases _p, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        price[_p] = amount;
    }

    function claim() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }('');
        require(success);
    }

    function claim(IERC20 token) external onlyOwner {
        SafeERC20.safeTransfer(
            token,
            msg.sender,
            token.balanceOf(address(this))
        );
    }

    // Metadata
    function setTokenURI(string calldata uri_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setTokenURI(uri_);
    }

    function baseTokenURI() external view returns (string memory) {
        return _tokenURI;
    }

    // Signer
    function setSigner(Phases _p, address _signer)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        signer[_p] = _signer;
    }

    function setFilter(bool v) external onlyRole(DEFAULT_ADMIN_ROLE) {
        filter = v;
    }

    // Phases
    function setPause(bool pause) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (pause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setPhase(Phases _phase) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (
            _phase == Phases.OGLIST ||
            _phase == Phases.WHITELIST ||
            _phase == Phases.WAITLIST
        ) {
            require(signer[_phase] != address(0), 'Signer address is not set');
        }
        phase = _phase;
    }

    function setMaxSupply(uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        MAX_SUPPLY = amount;
    }

    function setMaxPerTx(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxPerTx = amount;
    }

    // Set default royalty to be used for all token sale
    function setDefaultRoyalty(address _receiver, uint96 _fraction)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDefaultRoyalty(_receiver, _fraction);
    }

    function setTokenRoyalty(
        uint256 _tokenId,
        address _receiver,
        uint96 _fraction
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenRoyalty(_tokenId, _receiver, _fraction);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Base, AccessControl)
        returns (bool)
    {
        return
            ERC721Base.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }
}