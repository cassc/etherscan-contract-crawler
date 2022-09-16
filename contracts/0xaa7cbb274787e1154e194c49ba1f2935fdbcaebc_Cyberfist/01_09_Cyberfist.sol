// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "ERC721A/ERC721A.sol";
import "ERC721A/IERC721A.sol";

import "contract/SignedRedeemer.sol";

import "openzeppelin-contracts/contracts/utils/Address.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract Cyberfist is ERC721A, Ownable, SignedRedeemer {
    using Address for address;
    using Strings for string;

    uint256 public constant MAX_SUPPLY = 10000;

    uint256 public publicMintPrice = 0.015 ether;
    uint256 public presaleMintPrice = 0.01 ether;

    string public baseURI_;

    bool public isSaleActive;
    bool public isPresaleActive;
    bool public isRedemptionActive;
    bool public airdropped;
    bool public metadataFrozen;

    uint256 public maxPerWallet = 100;

    mapping(address => uint256) public redeemed;

    address public developer;

    IERC721A private migratedContract;

    constructor(address _admin, address _signer, address _migratedContract)
        SignedRedeemer(_signer)
        ERC721A("Cyberfirst", "CF")
    {
        developer = msg.sender;
        transferOwnership(_admin);

        migratedContract = IERC721A(_migratedContract);
    }

    function ownerAirdrop() public onlyAuthorized {
        require(!airdropped, "Already airdropped");
        uint256 _totalSupply = migratedContract.totalSupply();
        for (uint256 token = 0; token < _totalSupply; token++) {
            address owner = migratedContract.ownerOf(token);

            uint256 numRedeemed = redeemed[owner];
            redeemed[owner] = numRedeemed + 1;

            _safeMint(owner, 1);
        }
        airdropped = true;
    }

    function presaleMint(uint256 _amount, address _to, uint256 _allocated, bytes memory _signature) public payable {
        require(isPresaleActive, "Presale is not active");
        require(msg.value == (presaleMintPrice * _amount), "Incorrect mint price");

        _performAllocatedRedemption(_amount, _to, _allocated, _signature);
    }

    function redeem(uint256 _amount, address _to, uint256 _allocated, bytes memory _signature) public {
        require(isRedemptionActive, "Redemption not active");
        _performAllocatedRedemption(_amount, _to, _allocated, _signature);
    }

    function publicMint(uint256 _amount, address _to) public payable {
        require(isSaleActive, "Sale is not active");
        require(_amount + _numberMinted(_to) <= maxPerWallet, "Exceeds max per wallet");
        require(msg.value == (publicMintPrice * _amount), "Incorrect mint price");

        _performMint(_to, _amount);
    }

    function _performAllocatedRedemption(uint256 _amount, address _to, uint256 _allocated, bytes memory _signature)
        private
    {
        require(validateAllocation(_signature, _allocated, msg.sender), "Invalid Signature");
        uint256 numRedeemed = redeemed[msg.sender];

        // If allocated is something other than valid, it won't pass signature validation
        require(numRedeemed + _amount <= _allocated, "Cannot redeem that many");

        redeemed[msg.sender] = numRedeemed + _amount;
        _performMint(_to, _amount);
    }

    function ownerMint(address _to, uint256 _amount) public onlyOwner {
        require(_amount + totalSupply() <= MAX_SUPPLY, "Exceeds max supply");
        _safeMint(_to, _amount);
    }

    function _performMint(address _to, uint256 _amount) private {
        require(_amount + totalSupply() <= MAX_SUPPLY, "Exceeds max supply");

        _safeMint(_to, _amount);
    }

    function numberMinted(address by) public view returns (uint256) {
        return _numberMinted(by);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI_;
    }

    function supportsInterface(bytes4 interfaceID) public view override returns (bool) {
        return ERC721A.supportsInterface(interfaceID);
    }

    function setMigratedContract(address _migratedContract) public onlyAuthorized {
        require(!airdropped, "Already airdropped");
        migratedContract = IERC721A(_migratedContract);
    }

    function setBaseURI(string memory __baseURI) public onlyAuthorized {
        require(!metadataFrozen, "Metadata Frozen");
        baseURI_ = __baseURI;
    }

    function freezeMetadata() public onlyAuthorized {
        metadataFrozen = true;
    }

    function setIsSaleActive(bool _isSaleActive) public onlyAuthorized {
        isSaleActive = _isSaleActive;
    }

    function setIsPresaleActive(bool _isPresaleActive) public onlyAuthorized {
        isPresaleActive = _isPresaleActive;
    }

    function setIsRedemptionActive(bool _isRedemptionActive) public onlyAuthorized {
        isRedemptionActive = _isRedemptionActive;
    }

    function setPresaleMintPrice(uint256 _presaleMintPrice) public onlyAuthorized {
        presaleMintPrice = _presaleMintPrice;
    }

    function setPublicMintPrice(uint256 _publicMintPrice) public onlyAuthorized {
        publicMintPrice = _publicMintPrice;
    }

    function setMaxMintPerWallet(uint256 _maxPerWallet) public onlyAuthorized {
        maxPerWallet = _maxPerWallet;
    }

    function withdrawTo(address to, uint256 amount) public onlyOwner {
        if (to == address(0)) {
            to = _msgSender();
        }
        if (amount == 0) {
            amount = address(this).balance;
        }
        Address.sendValue(payable(to), amount);
    }

    modifier onlyAuthorized() {
        checkAuthorized();
        _;
    }

    function checkAuthorized() private view {
        require(msg.sender == owner() || msg.sender == developer, "Unauthorized");
    }
}