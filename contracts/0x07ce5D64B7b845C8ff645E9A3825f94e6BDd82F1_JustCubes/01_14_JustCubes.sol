// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**

                   .+------+     +------+     +------+     +------+     +------+.
                 .' |    .'|    /|     /|     |      |     |\     |\    |`.    | `.
                +---+--+'  |   +-+----+ |     +------+     | +----+-+   |  `+--+---+
                |   |  |   |   | |    | |     |      |     | |    | |   |   |  |   |
                |  ,+--+---+   | +----+-+     +------+     +-+----+ |   +---+--+   |
                |.'    | .'    |/     |/      |      |      \|     \|    `. |   `. |
                +------+'      +------+       +------+       +------+      `+------+

          .----------------.  .----------------.  .----------------.  .----------------. 
         | .--------------. || .--------------. || .--------------. || .--------------. |
         | |     _____    | || | _____  _____ | || |    _______   | || |  _________   | |
         | |    |_   _|   | || ||_   _||_   _|| || |   /  ___  |  | || | |  _   _  |  | |
         | |      | |     | || |  | |    | |  | || |  |  (__ \_|  | || | |_/ | | \_|  | |
         | |   _  | |     | || |  | '    ' |  | || |   '.___`-.   | || |     | |      | |
         | |  | |_' |     | || |   \ `--' /   | || |  |`\____) |  | || |    _| |_     | |
         | |  `.___.'     | || |    `.__.'    | || |  |_______.'  | || |   |_____|    | |
         | |              | || |              | || |              | || |              | |
         | '--------------' || '--------------' || '--------------' || '--------------' |
         '----------------'  '----------------'  '----------------'  '----------------' 

 .----------------.  .----------------.  .----------------.  .----------------.  .----------------. 
| .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
| |     ______   | || | _____  _____ | || |   ______     | || |  _________   | || |    _______   | |
| |   .' ___  |  | || ||_   _||_   _|| || |  |_   _ \    | || | |_   ___  |  | || |   /  ___  |  | |
| |  / .'   \_|  | || |  | |    | |  | || |    | |_) |   | || |   | |_  \_|  | || |  |  (__ \_|  | |
| |  | |         | || |  | '    ' |  | || |    |  __'.   | || |   |  _|  _   | || |   '.___`-.   | |
| |  \ `.___.'\  | || |   \ `--' /   | || |   _| |__) |  | || |  _| |___/ |  | || |  |`\____) |  | |
| |   `._____.'  | || |    `.__.'    | || |  |_______/   | || | |_________|  | || |  |_______.'  | |
| |              | || |              | || |              | || |              | || |              | |
| '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
 '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 


 */

contract JustCubes is ERC721A, Ownable, ReentrancyGuard {

    mapping (address => uint256) public numberOfWLMintsOnAddress;

    //Sale flags
    bool public OGsaleActive = false;
    bool public WLsaleActive = false;
    bool public saleActive = false;

    //Mint limits
    uint public immutable ADDRESS_MAX_MINTS = 5;
    uint public immutable ADDRESS_WL_MAX_MINTS = 2;
    uint public immutable PUBLIC_MINT_PER_TX = 2;

    //Supply
    uint256 public maxSupply = 8888;
    uint256 public reservedSupply = 200;

    //Pricing
    uint256 public OGprice = 0.045 ether;
    uint256 public WLprice = 0.085 ether;
    uint256 public price = 0.09 ether;

    //Pre-reveal IPFS link
    string private _baseTokenURI = "";

    //Merkle roots
    bytes32 public OGMerkleRoot;
    bytes32 public WLMerkleRoot;

    //Payable addresses
    address private constant AL_ADDRESS = 0x4Ee72eab8321Fb265Fd9fE6eeFee14D0a1A1906C;
    address private constant CR_ADDRESS = 0x022c875cda743a687a2669f5515408D7bC6aF755;
    address private constant AD_ADDRESS = 0xa3712A3C873E06026cbCBE14727Bf6010F671738;
    address private constant PROJ_ADDRESS = 0x11b2E4Ea2e759da33fB6F35bD4031F6E40046D26;
    address private constant AA_ADDRESS = 0x5f208bD3AD1e6F67bd68833e04efc8263A51b467;
    address private constant DEV_ADDRESS = 0xcEB5E5c55bB585CFaEF92aeB1609C4384Ec1890e;
    address private constant SKIN_ADDRESS = 0xAc839AaE0afc40131fCCaA1FCe5C53e6b13AbA8B;
    address private constant MA_ADDRESS = 0x29AE4c46dAE9cb298A2398AAb348769426900903;
    address private constant LE_ADDRESS = 0x30e37464499Deb7681030eCcB33793E33e833402;
    address private constant KY_ADDRESS = 0x927705920d0E697559718A16E283C458E75975f4;
    address private constant BR_ADDRESS = 0x5D8906c28a43bD2E99680b7552963d196602bE84;
    address private constant RY_ADDRESS = 0x55E29AdA6fA377D75cAAB61e391aa5FC188960b2;
    address private constant ZA_ADDRESS = 0x2b878dcb33490FE671ADf704c6388aBB569F4E18;
    address private constant ML_ADDRESS = 0xFD43A900AC4380Fd7e39775602B5EE2F341F8Dfe;

    constructor() ERC721A("JustCubes", "CUBE", 5, 8888) {
    }
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
     * OG mint
     */
    function mintOGSale(uint256 numberOfMints, bytes32[] calldata _merkleProof) external payable {

        require(OGsaleActive, "Presale must be active to mint");    

        require(MerkleProof.verify(_merkleProof, OGMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Invalid proof - Caller not whitelisted");

        require(numberOfMints > 0, "Sender is trying to mint none");
        require(numberMinted(msg.sender) + numberOfMints <= ADDRESS_MAX_MINTS, "Sender is trying to mint more than allocated tokens");
        require(numberOfWLMintsOnAddress[msg.sender] + numberOfMints <=  ADDRESS_WL_MAX_MINTS, "Sender is trying to mint more than their whitelist amount");
        require(totalSupply() + numberOfMints <= maxSupply, "This would exceed the max number of mints");
        require(msg.value >= numberOfMints * OGprice, "Not enough ether to mint");

        numberOfWLMintsOnAddress[msg.sender] += numberOfMints;
        _safeMint(msg.sender, numberOfMints);
    }

    /**
     * Whitelist mint
     */
    function mintWLSale(uint256 numberOfMints, bytes32[] calldata _merkleProof) external payable {
        
        require(WLsaleActive, "Sale must be active to mint"); 

        require(MerkleProof.verify(_merkleProof, WLMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Invalid proof - Caller not whitelisted");

        require(numberOfMints > 0, "Sender is trying to mint none");
        require(numberMinted(msg.sender) + numberOfMints <= ADDRESS_MAX_MINTS, "Sender is trying to mint more than allocated tokens");
        require(numberOfWLMintsOnAddress[msg.sender] + numberOfMints <= ADDRESS_WL_MAX_MINTS, "Sender is trying to mint more than their whitelist amount");
        require(totalSupply() + numberOfMints <= maxSupply, "Mint would exceed max supply of mints");
        require(msg.value >= numberOfMints * WLprice, "Amount of ether is not enough");

        numberOfWLMintsOnAddress[msg.sender] += numberOfMints;
        _safeMint(msg.sender, numberOfMints);

    }

    /**
     * Public mint
     */
    function mint(uint256 numberOfMints) external payable callerIsUser {

        require(saleActive, "Sale must be active to mint");
        require(numberOfMints > 0, "Sender is trying to mint none");
        require(numberOfMints <= PUBLIC_MINT_PER_TX, "Sender is trying to mint too many in a single transaction");
        require(numberMinted(msg.sender) + numberOfMints <= ADDRESS_MAX_MINTS, "Sender is trying to mint more than allocated tokens");
        require(totalSupply() + numberOfMints <= maxSupply, "Mint would exceed max supply of mints");
        require(msg.value >= numberOfMints * price, "Amount of ether is not enough");

        _safeMint(msg.sender, numberOfMints);
    }

    /**
     * Reserve mint for founders
     */
    function reserveMint(uint256 quantity) external onlyOwner {

        require(totalSupply() + quantity <= reservedSupply, "Too many minted to public to perform dev mint");
        require(quantity % ADDRESS_MAX_MINTS == 0, "Must only mint a multiple of the maximum address mints");
    
        uint256 numChunks = quantity / ADDRESS_MAX_MINTS;
    
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, ADDRESS_MAX_MINTS);
        }
    }

    function toggleOGSale() external onlyOwner {
        OGsaleActive = !OGsaleActive;
    }

    function toggleWLSale() external onlyOwner {
        WLsaleActive = !WLsaleActive;
    }

    function toggleSale() external onlyOwner {
        saleActive = !saleActive;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setOGMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        OGMerkleRoot = newMerkleRoot;
    }

     function setWLMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        WLMerkleRoot = newMerkleRoot;
    }

    function setSupply(uint256 newSupply) external onlyOwner {
        require(newSupply < maxSupply, "Cannot increase supply of tokens");
        maxSupply = newSupply;
    }
    
    function withdraw() external onlyOwner nonReentrant {
        require(address(this).balance > 0, "No balance to withdraw");
        uint256 contractBalance = address(this).balance;

        _withdraw(AL_ADDRESS, contractBalance * 19 / 100);
        _withdraw(CR_ADDRESS, contractBalance * 19 / 100);
        _withdraw(AD_ADDRESS, contractBalance * 19 / 100);
        _withdraw(PROJ_ADDRESS, contractBalance * 20 / 100);
        _withdraw(AA_ADDRESS, contractBalance * 5 / 100);
        _withdraw(DEV_ADDRESS, contractBalance * 9 / 100);
        _withdraw(SKIN_ADDRESS, contractBalance * 3 / 100);
        _withdraw(MA_ADDRESS, contractBalance * 1 / 100);
        _withdraw(LE_ADDRESS, contractBalance * 1 / 100);
        _withdraw(KY_ADDRESS, contractBalance * 5 / 1000);
        _withdraw(BR_ADDRESS, contractBalance * 5 / 1000);
        _withdraw(RY_ADDRESS, contractBalance * 1 / 100);
        _withdraw(ZA_ADDRESS, contractBalance * 1 / 100);
        _withdraw(ML_ADDRESS, contractBalance * 1 / 100);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function tokenIdOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }
}