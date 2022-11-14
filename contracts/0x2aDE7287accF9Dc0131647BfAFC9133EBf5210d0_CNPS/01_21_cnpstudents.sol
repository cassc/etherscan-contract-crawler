// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import {BitOpe} from "./libs/BitOpe.sol";
import "./interface/ITokenURI.sol";
import "./interface/IContractAllowListProxy.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";

abstract contract CNPScore is Ownable {
    enum Phase {
        BeforeMint,
        ALMint,
        BurnMint
    }

    // Upgradable FullOnChain
    ITokenURI public tokenuri;
    IContractAllowListProxy public cal;

    address public constant WITHDRAW_ADDRESS = 0xb3AE2992D47562B1ffa3FBA2768B8E5E04d4a907;
    address public constant OWNER_ADDRESS = 0x87d71224204e1438919743001376484a57b02d7c;
    address public constant CONTRIBUTOR_ADDRESS_1 = 0x18DaffB93902Ee2c20E48B664bF3b11315eED69B;
    address public constant CONTRIBUTOR_ADDRESS_2 = 0x7043B52Bed900e6bb3E144958b78F51d3FBD73b1;
    address public constant CONTRIBUTOR_ADDRESS_3 = 0xF8D81e6fa6F2096D7258d8FD2b6567614A6b6e82;
    address public constant CONTRIBUTOR_ADDRESS_4 = 0x11D9090E17A2aBC00e1a309f42997B274E543cB6;
    address public constant CONTRIBUTOR_ADDRESS_5 = 0xBB8FfB94269fE5a40AD793a1697dbf5E58831867;
    address public constant CONTRIBUTOR_ADDRESS_6 = 0x501790C6890dFA43c264AeE4Ed9aA5E116d0A0d4;

    uint256 public constant MAX_SUPPLY = 6000;
    bytes32 internal constant ADMIN = keccak256("ADMIN");

    uint256 public maxBurnMint = 2000;
    uint256 public limitGroup; // 0 start
    uint256 public cost = 0.001 ether;
    string public baseURI = "https://nft.web3youth.xyz/json/";
    string public baseExtension = ".json";
    bytes32 public merkleRoot;
    uint256 public alcount; // max:65535 Always raiseOrder
    uint256 public bmcount; // max:65535 Always raiseOrder
    Phase public phase = Phase.BeforeMint;
    address public royaltyAddress = WITHDRAW_ADDRESS;
    uint96 public royaltyFee = 1000; // default:10%
    uint256 public calLevel = 1;
    uint256 public finishTime = 1668421800; //2022-11-14 19:30:00 +09:00
    uint256 public saleCountForFinishTime; // 0 start
}

abstract contract CNPSadmin is
    CNPScore,
    AccessControl,
    ERC721AQueryable,
    ERC2981,
    DefaultOperatorFilterer
{
    using BitOpe for uint256;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, IERC721A, ERC721A, ERC2981)
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            interfaceId == type(IERC721A).interfaceId ||
            interfaceId == type(ERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // modifier
    modifier onlyAdmin() {
        require(hasRole(ADMIN, msg.sender), "You are not authorized.");
        _;
    }

    // onlyOwner
    function setAdminRole(address[] memory admins) external onlyOwner {
        for (uint256 i = 0; i < admins.length; i++) {
            _grantRole(ADMIN, admins[i]);
        }
    }

    function revokeAdminRole(address[] memory admins) external onlyOwner {
        for (uint256 i = 0; i < admins.length; i++) {
            _revokeRole(ADMIN, admins[i]);
        }
    }

    function airdropMint(
        address[] calldata _airdropAddresses,
        uint256[] memory _userMintAmount
    ) public onlyOwner {
        uint256 supply = totalSupply();
        uint256 _mintAmount = 0;
        for (uint256 i = 0; i < _userMintAmount.length; i++) {
            _mintAmount += _userMintAmount[i];
        }
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(supply + _mintAmount <= MAX_SUPPLY, "max NFT limit exceeded");

        for (uint256 i = 0; i < _userMintAmount.length; i++) {
            _safeMint(_airdropAddresses[i], _userMintAmount[i]);
        }
    }

    // onlyAdmin
    function setMaxBurnMint(uint256 _value) external onlyAdmin {
        maxBurnMint = _value;
    }

    function setCost(uint256 _value) external onlyAdmin {
        cost = _value;
    }

    function setBaseURI(string memory _newBaseURI) external onlyAdmin {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        external
        onlyAdmin
    {
        baseExtension = _newBaseExtension;
    }

    function setPhase(Phase _newPhase) external onlyAdmin {
        //0:BeroreMint > Always Stop Sale (1 -> 0 , 2 -> 0)
        //1:ALMint > Mint Start (0 -> 1)
        //2:BurnMint  > BurnMint Start (1 -> 2)
        phase = _newPhase;
    }

    function setLimitGroup(uint256 _value) external onlyAdmin {
        limitGroup = _value;
    }

    function setAlcount() external onlyAdmin {
        require(
            phase == Phase.BeforeMint,
            "out-of-scope phase that can be set"
        );
        require(alcount < 65535, "no Valid");
        unchecked {
            alcount += 1;
        }
    }

    function setBMcount() external onlyAdmin {
        require(
            phase == Phase.BeforeMint,
            "out-of-scope phase that can be set"
        );
        require(bmcount < 65535, "no Valid");
        unchecked {
            bmcount += 1;
        }
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyAdmin {
        merkleRoot = _merkleRoot;
    }

    function withdraw() external onlyAdmin {
        (bool os, ) = payable(WITHDRAW_ADDRESS).call{
            value: address(this).balance
        }("");
        require(os);
    }

    function setRoyaltyFee(uint96 _feeNumerator) external onlyAdmin {
        royaltyFee = _feeNumerator; // set Default Royalty._feeNumerator 500 = 5% Royalty
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    function setRoyaltyAddress(address _royaltyAddress) external onlyAdmin {
        royaltyAddress = _royaltyAddress; //Change the royalty address where royalty payouts are sent
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    function setTokenURI(ITokenURI _tokenuri) external onlyAdmin {
        tokenuri = _tokenuri;
    }

    function setCalContract(IContractAllowListProxy _cal) external onlyAdmin {
        cal = _cal;
    }

    function setCalLevel(uint256 _value) external onlyAdmin {
        calLevel = _value;
    }

    function setFinishTime(uint256 _value) external onlyAdmin {
        finishTime = _value;
    }

    function setSaleCountForFinishTime(uint256 _value) external onlyAdmin {
        saleCountForFinishTime = _value;
    }
}

contract CNPS is CNPSadmin {
    using BitOpe for uint256;
    using BitOpe for uint64;

    constructor() ERC721A("CNP Students", "CNPS") {
        _safeMint(CONTRIBUTOR_ADDRESS_1, 1);
        _safeMint(CONTRIBUTOR_ADDRESS_2, 1);
        _safeMint(CONTRIBUTOR_ADDRESS_3, 1);
        _safeMint(CONTRIBUTOR_ADDRESS_4, 1);
        _safeMint(CONTRIBUTOR_ADDRESS_5, 1);
        _safeMint(CONTRIBUTOR_ADDRESS_1, 24);
        _safeMint(CONTRIBUTOR_ADDRESS_2, 34);
        _safeMint(CONTRIBUTOR_ADDRESS_3, 29);
        _safeMint(CONTRIBUTOR_ADDRESS_4, 24);
        _safeMint(CONTRIBUTOR_ADDRESS_5, 24);
        _safeMint(CONTRIBUTOR_ADDRESS_6, 9);
        _safeMint(OWNER_ADDRESS, 1000);

        _setRoleAdmin(ADMIN, ADMIN);
        _setupRole(ADMIN, msg.sender); // set owner as admin
    }

    // overrides
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override(IERC721A, ERC721A)
    {
        if (address(cal) != address(0)) {
            require(
                cal.isAllowed(operator, calLevel) == true,
                "address no list"
            );
        }

        super.setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 tokenId)
        public
        virtual
        override(IERC721A, ERC721A)
    {
        if (address(cal) != address(0)) {
            require(cal.isAllowed(to, calLevel) == true, "address no list");
        }

        super.approve(to, tokenId);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // aux->00..15:al_count,16..31:al_amount,32..47:burnmint_count,48..63:burnmint_amount
    function _resetALCount(address _owner) internal {
        uint64 _auxval = _getAux(_owner);
        if (_auxval.get16_forAux(0) < alcount) {
            _setAux(
                _owner,
                _auxval.set16_forAux(0, uint64(alcount)).set16_forAux(1, 0)
            ); // CountUp + Clear
        }
    }

    function _resetBMCount(address _owner) internal {
        uint64 _auxval = _getAux(_owner);
        if (_auxval.get16_forAux(2) < bmcount) {
            _setAux(
                _owner,
                _auxval.set16_forAux(2, uint64(bmcount)).set16_forAux(3, 0)
            ); // CountUp + Clear
        }
    }

    function _getAuxforALAmount(address _owner) internal returns (uint64) {
        _resetALCount(_owner);
        return _getAux(_owner).get16_forAux(1);
    }

    function _getAuxforBMAmount(address _owner) internal returns (uint64) {
        _resetBMCount(_owner);
        return _getAux(_owner).get16_forAux(3);
    }

    function _setAuxforAL(address _owner, uint64 _aux) internal {
        _resetALCount(_owner);
        _setAux(_owner, _getAux(_owner).set16_forAux(1, _aux));
    }

    function _setALmintedCount(address _owner, uint256 _mintAmount) internal {
        unchecked {
            _setAuxforAL(
                _owner,
                _getAuxforALAmount(_owner) + uint64(_mintAmount)
            );
        }
    }

    function _setAuxforBM(address _owner, uint64 _aux) internal {
        _resetBMCount(_owner);
        _setAux(_owner, _getAux(_owner).set16_forAux(3, _aux));
    }

    function _setBMmintedCount(address _owner, uint256 _mintAmount) internal {
        unchecked {
            _setAuxforBM(
                _owner,
                _getAuxforBMAmount(_owner) + uint64(_mintAmount)
            );
        }
    }

    // public
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(IERC721A, ERC721A)
        returns (string memory)
    {
        if (address(tokenuri) == address(0)) {
            return
                string(
                    abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension)
                );
        } else {
            // Full-on chain support
            return tokenuri.tokenURI_future(tokenId);
        }
    }

    function getALRemain(
        address _address,
        uint256 _alAmountMax,
        uint256 _alGroup,
        bytes32[] calldata _merkleProof
    ) public view returns (uint256) {
        uint256 _Amount = 0;
        if (phase == Phase.ALMint) {
            if (
                getALExit(_address, _alAmountMax, _alGroup, _merkleProof) ==
                true
            ) {
                if (_getAux(_address).get16_forAux(0) < alcount) {
                    _Amount = _alAmountMax;
                } else {
                    _Amount = _alAmountMax - _getAux(_address).get16_forAux(1);
                }
            }
        }
        return _Amount;
    }

    function getBMRemain(
        address _address,
        uint256 _alAmountMax,
        uint256 _alGroup,
        bytes32[] calldata _merkleProof
    ) public view returns (uint256) {
        uint256 _Amount = 0;
        if (phase == Phase.BurnMint) {
            if (
                getALExit(_address, _alAmountMax, _alGroup, _merkleProof) ==
                true
            ) {
                if (_getAux(_address).get16_forAux(2) < bmcount) {
                    _Amount = _alAmountMax;
                } else {
                    _Amount = _alAmountMax - _getAux(_address).get16_forAux(3);
                }
            }
        }
        return _Amount;
    }

    function getALExit(
        address _address,
        uint256 _alAmountMax,
        uint256 _alGroup,
        bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        bool _exit = false;
        bytes32 _leaf = keccak256(
            abi.encodePacked(_address, _alAmountMax, _alGroup)
        );

        if (
            MerkleProof.verifyCalldata(_merkleProof, merkleRoot, _leaf) == true
        ) {
            _exit = true;
        }

        return _exit;
    }

    // external
    function getTotalBurned() external view returns (uint256) {
        return _totalBurned();
    }

    function mint(
        uint256 _mintAmount,
        uint256 _alAmountMax,
        uint256 _alGroup,
        bytes32[] calldata _merkleProof
    ) external payable {
        require(phase == Phase.ALMint, "sale is not active");
        if (alcount == saleCountForFinishTime) {
            require(finishTime >= block.timestamp, "sale was finished");
        }
        require(_alGroup <= limitGroup, "not target group");
        require(tx.origin == msg.sender, "the caller is another controler");
        require(
            getALExit(msg.sender, _alAmountMax, _alGroup, _merkleProof) == true,
            "You don't have a Allowlist!"
        );
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        _resetALCount(msg.sender); // Always check reset before getALRemain
        require(
            _mintAmount <=
                getALRemain(msg.sender, _alAmountMax, _alGroup, _merkleProof),
            "claim is over max amount"
        );
        require(
            _mintAmount + totalSupply() <= MAX_SUPPLY,
            "claim is over the max supply"
        );
        require(msg.value >= cost * _mintAmount, "not enough eth");

        _setALmintedCount(msg.sender, _mintAmount);
        _safeMint(msg.sender, _mintAmount);
    }

    function burnMint(
        uint256[] memory _burnTokenIds,
        uint256 _alAmountMax,
        uint256 _alGroup,
        bytes32[] calldata _merkleProof
    ) external payable {
        require(phase == Phase.BurnMint, "sale is not active");
        require(_alGroup <= limitGroup, "not target group");
        require(tx.origin == msg.sender, "the caller is another controler");
        require(
            getALExit(msg.sender, _alAmountMax, _alGroup, _merkleProof) == true,
            "You don't have a Allowlist!"
        );
        require(_burnTokenIds.length > 0, "need to mint at least 1 NFT");
        _resetBMCount(msg.sender); // Always check reset before getBMRemain
        require(
            _burnTokenIds.length <=
                getBMRemain(msg.sender, _alAmountMax, _alGroup, _merkleProof),
            "claim is over max amount"
        );
        require(
            _burnTokenIds.length + _totalBurned() <= maxBurnMint,
            "over total burn count"
        );
        require(msg.value >= cost * _burnTokenIds.length, "not enough eth");

        _setBMmintedCount(msg.sender, _burnTokenIds.length);
        for (uint256 i = 0; i < _burnTokenIds.length; i++) {
            uint256 tokenId = _burnTokenIds[i];
            require(msg.sender == ownerOf(tokenId));
            _burn(tokenId);
        }
        _safeMint(msg.sender, _burnTokenIds.length);
    }
}