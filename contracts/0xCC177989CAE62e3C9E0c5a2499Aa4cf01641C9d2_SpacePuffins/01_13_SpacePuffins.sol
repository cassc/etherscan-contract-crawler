// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

//      _______..______      ___       ______  _______  
//     /       ||   _  \    /   \     /      ||   ____| 
//    |   (----`|  |_)  |  /  ^  \   |  ,----'|  |__    
//     \   \    |   ___/  /  /_\  \  |  |     |   __|   
// .----)   |   |  |     /  _____  \ |  `----.|  |____  
// |_______/    | _|    /__/     \__\ \______||_______| 
// .______    __    __   _______  _______  __  .__   __.      _______.
// |   _  \  |  |  |  | |   ____||   ____||  | |  \ |  |     /       |
// |  |_)  | |  |  |  | |  |__   |  |__   |  | |   \|  |    |   (----`
// |   ___/  |  |  |  | |   __|  |   __|  |  | |  . `  |     \   \    
// |  |      |  `--'  | |  |     |  |     |  | |  |\   | .----)   |   
// | _|       \______/  |__|     |__|     |__| |__| \__| |_______/                                                                                                                             
//                                                                                                                         
                                                                                                            
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./lib/AllowList.sol";
import "./lib/ContractMetadata.sol";

contract SpacePuffins is
    ERC721A,
    Ownable,
    ERC2981,
    ContractMetadata,
    AllowList
{
    uint16 public constant maxSupply = 5000;
    uint16 public maxAllowListMintsPerAddress = 5;
    uint16 public maxFreeMintSupply = 900;
    uint16 public totalFreeMinted = 0;
    uint16 public maxPublicMintsPerAddress = 100;
    uint256 public price = 0.007 ether;
    address payable public withdrawAddress;
    string private _spBaseURI;

    enum Phase {
        Premint,
        AllowListMint,
        PublicMint,
        SoldOut
    }
    event PhaseShift(Phase newPhase);
    Phase public phase;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseUri_,
        string memory contractUri_,
        uint96 royalty_
    ) ERC721A(name_, symbol_) {
        setBaseURI(baseUri_);
        setContractMetadataUri(contractUri_);
        _setDefaultRoyalty(msg.sender, royalty_);
        setWithdrawAddress(payable(msg.sender));
        setPhase(Phase.Premint);
        _mintERC2309(msg.sender, 100);
    }

    modifier checkSupply(uint256 quantity) {
        require(quantity + _totalMinted() <= maxSupply, "Exceeds max supply");
        _;
    }

    function totalMinted()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (_totalMinted(), maxSupply, totalFreeMinted, maxFreeMintSupply);
    }

    function remainingAllowListMints(address address_)
        public
        view
        returns (uint256)
    {
        return maxAllowListMintsPerAddress - _getAux(address_);
    }

    function allowListMint(uint256 quantity, bytes32[] calldata proof)
        external
        payable
        onlyAllowList(proof)
        checkSupply(quantity)
    {
        require(phase == Phase.AllowListMint, "AllowList: mint not open");

        uint64 totalMinted_ = _getAux(msg.sender);
        require(totalMinted_ + quantity <= maxAllowListMintsPerAddress, "AllowList: max mints is 5");

        bool freeMintEligible = (totalFreeMinted < maxFreeMintSupply &&
            totalMinted_ == 0);
        uint256 cost = _allowListMintCost(freeMintEligible, quantity);
        require(msg.value >= cost, "AllowList: Insufficient Funds");

        _mint(msg.sender, quantity);
        _setAux(msg.sender, totalMinted_ + uint64(quantity));
        if (freeMintEligible) {
            totalFreeMinted++;
        }
    }

    function mint(uint256 quantity) external payable checkSupply(quantity) {
        require(phase == Phase.PublicMint, "Public Mint: not open");
        require(
            _numberMinted(msg.sender) + quantity <= maxPublicMintsPerAddress,
            "Public Mint: reached max per wallet"
        );
        require(
            msg.value >= price * quantity,
            "Public Mint: Insufficient Funds"
        );

        _mint(msg.sender, quantity);
    }

    // =============================================================
    //                          PRIVATE
    // =============================================================

    function _allowListMintCost(bool freeMintEligible, uint256 quantity)
        private
        view
        returns (uint256)
    {
        if (freeMintEligible) {
            return (quantity - 1) * price;
        } else {
            return quantity * price;
        }
    }

    // =============================================================
    //                          OWNER ONLY
    // =============================================================

    function setWithdrawAddress(address payable withdrawAddress_)
        public
        onlyOwner
    {
        require(withdrawAddress_ != address(0), "Withdraw address is zero");
        withdrawAddress = withdrawAddress_;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setPhase(Phase phase_) public onlyOwner {
        phase = phase_;
        emit PhaseShift(phase);
    }

    function setPrice(uint256 price_) public onlyOwner {
        price = price_;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _spBaseURI = newBaseURI;
    }

    function setTotalFreeMinted(uint16 totalFreeMinted_) public onlyOwner {
        totalFreeMinted = totalFreeMinted_;
    }

    function setMaxAllowListMintsPerAddress(uint16 maxAllowListMintsPerAddress_) public onlyOwner {
        maxAllowListMintsPerAddress = maxAllowListMintsPerAddress_;
    }

    function setMaxFreeMintSupply(uint16 maxFreeMintSupply_) public onlyOwner {
        maxFreeMintSupply = maxFreeMintSupply_;
    }

    function setMaxPublicMintsPerAddress(uint16 maxPublicMintsPerAddress_) public onlyOwner {
        maxPublicMintsPerAddress = maxPublicMintsPerAddress_;
    }

    function setAllowListRoot(bytes32 allowListRoot) public onlyOwner {
        _setAllowListRoot(allowListRoot);
    }

    function setContractMetadataUri(string memory contractMetaDataUri_)
        public
        onlyOwner
    {
        _setContractMetadataUri(contractMetaDataUri_);
    }

    function batchMint(
        address[] calldata addresses,
        uint16[] calldata quantities
    ) public onlyOwner {
        for (uint16 i = 0; i < addresses.length; i++) {
            require(
                quantities[i] + _totalMinted() <= maxSupply,
                "Exceeds max supply"
            );
            _mint(addresses[i], quantities[i]);
        }
    }

    // =============================================================
    //                          OVERRIDES
    // =============================================================

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return _spBaseURI;
    }

    // IERC165
    // see https://chiru-labs.github.io/ERC721A/#/migration?id=supportsinterface
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}