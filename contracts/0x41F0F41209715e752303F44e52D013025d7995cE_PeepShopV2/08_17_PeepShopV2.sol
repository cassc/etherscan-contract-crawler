// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import 'erc721a-upgradeable/contracts/extensions/ERC721ABurnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {OperatorFiltererUpgradeable} from "operator-filter-registry/src/upgradeable/OperatorFiltererUpgradeable.sol";

contract PeepShopV2 is ERC721AUpgradeable, ERC721ABurnableUpgradeable, OperatorFiltererUpgradeable, OwnableUpgradeable{
    using Strings for uint256;

    /**
     * Structure for peepshop sale/mint
     */
    struct MintSettings{
        uint256 supply;
        uint256 price;
        uint256 maxWallet;
        uint256 mintedSupply;
        uint256 phaseEnd;
        bytes32 merkleRoot;
    }

    enum MintPhase{
        STEALTH,
        PEEPLIST,
        PEEPFRENS,
        PUBLIC
    }

    MintPhase public currPhase;

    uint256 public maxSupply;

    bool public isMintingPaused;
    bool public isRevealed;

    string public baseTokenUri;
    string public placeHolderTokenUri;

    mapping(MintPhase => MintSettings) public saleData;
    mapping(address => mapping(MintPhase => uint256)) public userMintCount;

    address public treasuryAddress;

    event peepMinted(MintPhase _mintPhase, address _minter, uint256 _qty);

    modifier saleCondition(bytes32[] memory _merkleProof, uint256 _qty){
        require(!isMintingPaused, "PeepShop :: Minting Paused");
        require((_qty + userMintCount[msg.sender][currPhase]) <= saleData[currPhase].maxWallet, "PeepShop :: Beyond max wallet!");
        require(msg.value >= (saleData[currPhase].price * _qty), "PeepShop :: not enough payment!");
        require((saleData[currPhase].mintedSupply + _qty) <= saleData[currPhase].supply, "PeepShop :: Beyond phase supply!");

        if(currPhase == MintPhase.PEEPLIST || currPhase == MintPhase.PEEPFRENS){
            bytes32 sender = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProofUpgradeable.verify(_merkleProof, saleData[currPhase].merkleRoot, sender), "PeepShop :: You're not in the list!");
        }

        saleData[currPhase].mintedSupply += _qty;
        userMintCount[msg.sender][currPhase] += _qty;
        _;
    }

    function initialize() initializerERC721A initializer external{
        __ERC721A_init('PEEPSHOP','PEEPSHOP');
        __Ownable_init();

        maxSupply = 3333;

        treasuryAddress = 0xDBBF951682F35a00085e699E19531cE08C886Ad8;

        //Stealth sale set up
        saleData[MintPhase.STEALTH].supply = 1600;
        saleData[MintPhase.STEALTH].price = 0.00999 ether;
        saleData[MintPhase.STEALTH].maxWallet = 3;

        //Peeplist sale set up
        saleData[MintPhase.PEEPLIST].supply = 1636;
        saleData[MintPhase.PEEPLIST].price =  0.00888 ether;
        saleData[MintPhase.PEEPLIST].maxWallet = 1;

        //Peepfrens sale set up
        saleData[MintPhase.PEEPFRENS].supply = 150;
        saleData[MintPhase.PEEPFRENS].price = 0 ether;
        saleData[MintPhase.PEEPFRENS].maxWallet = 1;

        //Public sale set up
        saleData[MintPhase.PUBLIC].price = 0.00999 ether;
        saleData[MintPhase.PUBLIC].maxWallet = 5;

        __OperatorFilterer_init(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6, true);
    }

    /**
     * Public Functions
     */

    function peepShopMint(bytes32[] memory _merkleProof, uint256 _qty) payable external saleCondition(_merkleProof, _qty){
        _mint(msg.sender, _qty);
        
        payable(treasuryAddress).transfer(msg.value);

        emit peepMinted(currPhase, msg.sender, _qty);
    }

    /**
     * View Functions
     */

    function tokenURI(uint256 tokenId) public view virtual override(ERC721AUpgradeable, IERC721AUpgradeable) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId + 1;

        if(!isRevealed){
            return placeHolderTokenUri;
        }
        //string memory baseURI = _baseURI();
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }
    
    /**
     * Administrative Functions
     */

    function setMerkleRoot(MintPhase _mintPhase, bytes32 _merkleRoot) external onlyOwner{
        saleData[_mintPhase].merkleRoot = _merkleRoot;
    }    

    function setSalePaused() external onlyOwner{
        isMintingPaused = !isMintingPaused;
    }

    function setBaseUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }
    
    function setPlaceHolderTokenUri(string memory _placeHolderTokenUri) external onlyOwner{
        placeHolderTokenUri = _placeHolderTokenUri;
    }

    function setReveal() external onlyOwner{
        isRevealed = !isRevealed;
    }

    function setTreasuryAddress(address _treasuryAddress)external onlyOwner{
        treasuryAddress = _treasuryAddress;
    }

    function setSaleData(
        MintPhase _mintPhase,
        uint256 _supply,
        uint256 _price,
        uint256 _maxWallet
    )external onlyOwner{
        saleData[_mintPhase].supply = _supply;
        saleData[_mintPhase].price = _price;
        saleData[_mintPhase].maxWallet = _maxWallet;
    }

    //Toggle functions for sale phase

    function toggleStealthMint() external onlyOwner{
        currPhase = MintPhase.STEALTH;
    }

    function togglePeeplistMint() external onlyOwner{
        currPhase = MintPhase.PEEPLIST;
    }

    function togglePeepfrensMint() external onlyOwner{
        currPhase = MintPhase.PEEPFRENS;
    }

    function togglePublicMint() external onlyOwner{
        currPhase = MintPhase.PUBLIC;

        uint256 publicMintSupply = maxSupply - totalSupply();
        saleData[MintPhase.PUBLIC].supply = publicMintSupply;
    }

    /**
     *  Opensea Operator Filter Registry Impl
     */

     function setApprovalForAll(address operator, bool approved) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilterer(address subscriptionOrRegistrantToCopy, bool subscribe)
        external
        onlyOwner
    {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(operatorFilterRegistry).code.length > 0) {
            if (!operatorFilterRegistry.isRegistered(address(this))) {
                if (subscribe) {
                    operatorFilterRegistry.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    if (subscriptionOrRegistrantToCopy != address(0)) {
                        operatorFilterRegistry.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                    } else {
                        operatorFilterRegistry.register(address(this));
                    }
                }
            }
        }
    }
}