// SPDX-License-Identifier: UNLICENSE
pragma solidity >=0.8.0 <=0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract ERC1155SelfMinter is ERC1155, ReentrancyGuard, DefaultOperatorFilterer, Ownable {
    error TotalSupplyGreaterThanMaxSupply();
    error TierNumberIncorrect();
    error ArrayLengthsDiffer();
    error TierLengthTooShort();
    error PartnerAlreadyExists();
    error PartnerNotFound();
    error InvalidPartnerWallet();
    error InvalidPartnerSharePct();
    error PartnerActive();
    error PartnerDeactivated();
    error InvalidProof();
    error TierPeriodHasntStarted();
    error TierPeriodHasEnded();
    error MintLimitReached();
    error AlreadyInitialized();
    error MsgSenderIsNotOwner();

    using Strings for uint256;

    string public baseURI;
    string public metaDataExt = "";
    string public name;
    string public symbol;

    uint256 public mintFee;
    uint256 public saleId;
    uint256 public totalSupply;

    bool public paused;
    bool public initialized;

    address public multisig;
    address public token;
    address public treasuryWallet;

    mapping(uint256 => Tier) public tiers;
    mapping(uint256 => Supply) public supplyPerId;
    mapping(address => Partner) public partners;
    mapping(address => mapping(uint256 => Supply)) public partnersSupply;

    uint256 public maxPartnerSharePct = 10;

    mapping(address => uint256) public mintedPerAddress;
    mapping(address => bool) public isAdmin;

    event SetBaseURI(string indexed _baseURI);
    event SetStartTimestamp(uint256 indexed _timestamp);
    event TokenBurn(uint256[] indexed _tokenIds, uint256[] indexed _amounts, address indexed _user);
    event TierMint(address indexed user, uint256 indexed _tier, uint256 indexed _amount);
    event BatchMint(address indexed user, uint256 indexed _amount);
    event PartnerTierMint(address indexed user, uint256 indexed _tier, uint256 indexed _amount, address _partner);

    function _onlyAdminOrOwner(address _address) private view {
        require(
            isAdmin[_address] || _address == owner(),
            "This address is not allowed"
        );
    }

    modifier onlyAdminOrOwner(address _address) {
        _onlyAdminOrOwner(_address);
        _;
    }
    
    function _onlyMultiSig(address _address) private view {
        require(_address == multisig, "Not Multisig wallet");
    }

    modifier onlyMultiSig(address _address) {
        _onlyMultiSig(_address);
        _;
    }

    function _onlyUnpaused() private view {
        require(!paused, "Sale Stopped Currently");
    }

    modifier onlyUnpaused() {
        _onlyUnpaused();
        _;
    }

    struct Supply {
        uint256 max;
        uint256 total;
    }

    struct Tier {
        uint256 start;
        uint256 end;
        bytes32 merkleRoot;
        uint256 limitPerWalletPerTier;
        bool isPublic;
    }

    struct Partner {
        address walletAddress;
        uint256 sharePct;
        bool isActive;
    }

    constructor() ERC1155(""){}

    function initialize(
        address _multisig,
        address _token,
        string memory _baseURI,
        string memory _name,
        string memory _symbol,
        uint256 _fees,
        uint256[] memory tiersNumbers,
        uint256[] memory limitPerWalletPerTier,
        uint256[] memory starts,
        uint256[] memory ends,
        bytes32[] memory merkleRoots,
        bool[] memory isTierPublic
    ) public onlyAdminOrOwner(msg.sender) {
        if(initialized) revert AlreadyInitialized();
        if(tiersNumbers.length != starts.length) revert ArrayLengthsDiffer();
        if(tiersNumbers.length != ends.length) revert ArrayLengthsDiffer();
        if(tiersNumbers.length != merkleRoots.length) revert ArrayLengthsDiffer();
        if(tiersNumbers.length != limitPerWalletPerTier.length) revert ArrayLengthsDiffer();
        if(tiersNumbers.length != isTierPublic.length) revert ArrayLengthsDiffer();

        multisig = _multisig;
        token = _token;
        baseURI = _baseURI;
        mintFee = _fees;
        name = _name;
        symbol = _symbol;

        for (uint256 i = 0; i < tiersNumbers.length; i++) {
            tiers[tiersNumbers[i]] = Tier(starts[i], ends[i], merkleRoots[i], limitPerWalletPerTier[i], isTierPublic[i]);
        }

        emit SetBaseURI(baseURI);

        initialized = true;
    }

    function setSaleConfig(
        uint256 _fees,
        uint256[] memory tiersNumbers,
        uint256[] memory limitPerWalletPerTier,
        uint256[] memory starts,
        uint256[] memory ends,
        bytes32[] memory merkleRoots,
        bool[] memory isTierPublic
    ) public onlyAdminOrOwner(msg.sender) {
        if(tiersNumbers.length != starts.length) revert ArrayLengthsDiffer();
        if(tiersNumbers.length != ends.length) revert ArrayLengthsDiffer();
        if(tiersNumbers.length != merkleRoots.length) revert ArrayLengthsDiffer();
        if(tiersNumbers.length != limitPerWalletPerTier.length) revert ArrayLengthsDiffer();
        if(tiersNumbers.length != isTierPublic.length) revert ArrayLengthsDiffer();

        mintFee = _fees;

        for (uint256 i = 0; i < tiersNumbers.length; i++) {
            tiers[tiersNumbers[i]] = Tier(starts[i], ends[i], merkleRoots[i], limitPerWalletPerTier[i], isTierPublic[i]);
        }
    }

    //
    // Admin / Owner Functions
    //
    function setContractOwnership(address newOwner) public onlyOwner {
        transferOwnership(newOwner);
    }

    function setContractAdmin(address _address) public onlyOwner {
        isAdmin[_address] = true;
    }

    function setTreasury(address _addr) public onlyOwner {
        treasuryWallet = _addr;
    }

    function deleteContractAdmin(address _address) public onlyOwner {
        isAdmin[_address] = false;
    }

    function setTierTimes(
        uint256 tierNo,
        uint256 _startTime,
        uint256 _endTime
    ) public onlyOwner {
        if(_endTime < _startTime + 30) revert TierLengthTooShort();
        tiers[tierNo].start = _startTime;
        tiers[tierNo].end = _endTime;
    } 

    function setMultiSig(address _addr) public onlyMultiSig(msg.sender) {
        multisig = _addr;
    }

    function setPaymentToken(address _addr) external onlyMultiSig(msg.sender) {
        token = _addr;
    }

    function setMaxPartnerSharePct(uint256 maxShare) external onlyMultiSig(msg.sender) {
        maxPartnerSharePct = maxShare;
    }

    function partnerAdd(
        address partnerWallet,
        uint256 _sharePct
    ) external onlyMultiSig(msg.sender) {
        if(partners[partnerWallet].walletAddress != address(0)) revert PartnerAlreadyExists();
        if(partnerWallet == address(0)) revert InvalidPartnerWallet();
        if(_sharePct > maxPartnerSharePct) revert InvalidPartnerSharePct();

        partners[partnerWallet] = Partner({
            walletAddress: partnerWallet,
            sharePct: _sharePct,
            isActive: true
        });
    }

    function partnerUpdateSharePct(
        address partnerWallet,
        uint256 _sharePct
    ) external onlyMultiSig(msg.sender) {
        if(partners[partnerWallet].walletAddress == address(0)) revert PartnerNotFound();
        if(_sharePct > maxPartnerSharePct) revert InvalidPartnerSharePct();

        partners[partnerWallet].sharePct = _sharePct;
    }

    function partnerActivate(address partnerWallet) external onlyMultiSig(msg.sender) {
        if(partners[partnerWallet].walletAddress == address(0)) revert PartnerNotFound();
        if(partners[partnerWallet].isActive) revert PartnerActive();

        partners[partnerWallet].isActive = true;
    }

    function partnerDeactivate(address partnerWallet) external onlyMultiSig(msg.sender) {
        if(partners[partnerWallet].walletAddress == address(0)) revert PartnerNotFound();
        if(!partners[partnerWallet].isActive) revert PartnerDeactivated();

        partners[partnerWallet].isActive = false;
    }

    function partnerSetTokenIdMaxSupply(
        address partnerWallet,
        uint256 _tokenId,
        uint256 _maxSupply
    ) public onlyAdminOrOwner(msg.sender) {
        if (partners[partnerWallet].walletAddress == address(0)) revert PartnerNotFound();

        if (partnersSupply[partnerWallet][_tokenId].total == 0) {
            partnersSupply[partnerWallet][_tokenId] = Supply({
                max: _maxSupply, 
                total: 0
            });

            return;
        }

        if (partnersSupply[partnerWallet][_tokenId].total > _maxSupply) revert TotalSupplyGreaterThanMaxSupply();

        partnersSupply[partnerWallet][_tokenId].max = _maxSupply;
    }

    function collectTreasury() external onlyMultiSig(msg.sender) {
        if (address(token) == address(0)) {
            require (address(0) != treasuryWallet, "Invalid treasury wallet");

            (bool sent, bytes memory data) = treasuryWallet.call{value: address(this).balance}("");
            require(sent, "Failed to send Ether");
        } else {
            uint256 amt = ERC20(token).balanceOf(address(this));
            ERC20(token).transfer(treasuryWallet, amt);
        }
    }

    function emergencyPause(bool _paused) public onlyAdminOrOwner(msg.sender) {
        paused = _paused;
    }

    function setSaleTokenId(uint256 _tokenId) public onlyAdminOrOwner(msg.sender) {
        saleId = _tokenId;
    }

    function setMintFee(uint256 _mintFee) public onlyAdminOrOwner(msg.sender) {
        mintFee = _mintFee;
    }

    function setTierMerkleRoots(uint256 tierNo, bytes32 merkleRoots) public onlyAdminOrOwner(msg.sender) {
        tiers[tierNo].merkleRoot = merkleRoots;
    }

    function setTierLimitPerWallet(uint256 tierNo, uint256 limitPerWallet) public onlyAdminOrOwner(msg.sender) {
        tiers[tierNo].limitPerWalletPerTier = limitPerWallet;
    }

    function setTierIsPublic(uint256 tierNo, bool isPublic) public onlyAdminOrOwner(msg.sender) {
        tiers[tierNo].isPublic = isPublic;
    }

    function setNftMetadata(string memory _newBaseURI, string memory _newExt) public onlyAdminOrOwner(msg.sender) {
        baseURI = _newBaseURI;
        metaDataExt = _newExt;
    }

    function setTokenIdMaxSupply(uint256 _tokenId, uint256 _maxSupply) public onlyAdminOrOwner(msg.sender) {
        if (supplyPerId[_tokenId].total > _maxSupply) revert TotalSupplyGreaterThanMaxSupply();
        supplyPerId[_tokenId].max = _maxSupply;
    }

    function tierMint(
        address mintAddress,
        uint256 tierNo,
        uint256 amount,
        bytes32[] calldata _merkleProof
    ) external payable onlyUnpaused() {
        uint256 payment = mintFee * amount;

        _checks(mintAddress, tierNo, amount, _merkleProof);
        _mintFeeCheck(msg.sender, amount);
        
        if(supplyPerId[saleId].total + amount > supplyPerId[saleId].max)
            revert TotalSupplyGreaterThanMaxSupply();

        supplyPerId[saleId].total += amount;

        if (treasuryWallet != address(0)) {
            if(address(token) == address(0)){
                require(msg.value >= payment);
                
                (bool sent, bytes memory data) = treasuryWallet.call{value: msg.value}("");
                require(sent, "Failed to send Ether");
            } else {
                ERC20(token).transferFrom(msg.sender, treasuryWallet, payment);
            }
        }


        _mint(mintAddress, saleId, amount, "");

        totalSupply += amount;

        emit TierMint(mintAddress, tierNo, amount);
    }

    function batchMint(
        address mintAddress,
        uint256 amount
    ) external onlyUnpaused() onlyAdminOrOwner(msg.sender) {      
        if(supplyPerId[saleId].total + amount > supplyPerId[saleId].max)
            revert TotalSupplyGreaterThanMaxSupply();

        supplyPerId[saleId].total += amount;

        _mint(mintAddress, saleId, amount, "");

        totalSupply += amount;

        emit BatchMint(mintAddress, amount);
    }

    //
    // Partner operations
    //
    function partnerTierMint(
        address mintAddress,
        uint256 tierNo,
        uint256 amount,
        bytes32[] calldata _merkleProof,
        address partnerWallet
    ) external payable onlyUnpaused() {

        uint256 payment = mintFee * amount;

        if (partners[partnerWallet].walletAddress == address(0))
            revert PartnerNotFound();

        if (!partners[partnerWallet].isActive)
            revert PartnerDeactivated();

        if (partnersSupply[partnerWallet][saleId].total + amount > partnersSupply[partnerWallet][saleId].max)
            revert TotalSupplyGreaterThanMaxSupply();

        uint256 _partnerAmount;

        _checks(mintAddress, tierNo, amount, _merkleProof);
        _mintFeeCheck(msg.sender, amount);

        if (address(token) == address(0)) {
            require(msg.value >= payment);
            _partnerAmount = msg.value * partners[partnerWallet].sharePct / 100;

            if (treasuryWallet != address(0)) {
                (bool sent, bytes memory data) = treasuryWallet.call{value: msg.value - _partnerAmount}("");
                require(sent, "Failed to send Ether");
            }

            (bool _sent, bytes memory _data) = partnerWallet.call{value: _partnerAmount}("");
            require(_sent, "Failed to send Ether");

        } else {
            _partnerAmount = payment * partners[partnerWallet].sharePct / 100;

            if (treasuryWallet != address(0)) {
                ERC20(token).transferFrom(msg.sender, treasuryWallet, payment - _partnerAmount);
            }
            ERC20(token).transferFrom(msg.sender, partners[partnerWallet].walletAddress, _partnerAmount);
        }

        partnersSupply[partnerWallet][saleId].total += amount;

        _mint(mintAddress, saleId, amount, "");

        totalSupply += amount;

        emit PartnerTierMint(mintAddress, tierNo, amount, partnerWallet);
    }

    function burn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public {
        if(ids.length != amounts.length) revert ArrayLengthsDiffer();
        if(from != msg.sender) revert MsgSenderIsNotOwner();

        for(uint256 i=0; i < ids.length; i++){
            _burn(from, ids[i], amounts[i]);

            totalSupply -= amounts[i];
        }

        emit TokenBurn(ids, amounts, from);
    }

    function setApprovalForAll(
        address operator, 
        bool approved
    ) public override onlyAllowedOperatorApproval(operator){
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from, 
        address to, 
        uint256 id, 
        uint256 amount, 
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from, 
        address to, 
        uint256[] memory ids, 
        uint256[] memory amounts, 
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    //
    // View/Internal Functions
    //
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(bytes(baseURI).length > 0, "TokenUri: base URI is not set");
    
        return string(abi.encodePacked(baseURI, metaDataExt, tokenId.toString()));
    }

    function _checks(
        address mintAddress,
        uint256 tierNo,
        uint256 amount,
        bytes32[] calldata _merkleProof
    ) internal view {
        if(tierNo <= 0) revert TierNumberIncorrect();
        if(tiers[tierNo].start > block.timestamp) revert TierPeriodHasntStarted();
        if(tiers[tierNo].end < block.timestamp) revert TierPeriodHasEnded();

        if (tiers[tierNo].isPublic == false && !MerkleProof.verify(_merkleProof, tiers[tierNo].merkleRoot, keccak256(abi.encodePacked(mintAddress, tierNo)))) {
            revert InvalidProof();
        }

        if(mintedPerAddress[mintAddress] + amount > tiers[tierNo].limitPerWalletPerTier) revert MintLimitReached();
    }

    function _mintFeeCheck(address user, uint256 amount) internal view {
        if (address(token) == address(0)) {
            require(
                msg.value >= mintFee * amount,
                "doesn't have enough tokens to mint the NFT"
            );
        } else {
            require(
                ERC20(token).balanceOf(user) >= mintFee * amount,
                "doesn't have enough tokens to mint the NFT"
            );
        }
    }

    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal override {
        mintedPerAddress[to] += amount;

        super._mint(to, id, amount, data);
    }
}