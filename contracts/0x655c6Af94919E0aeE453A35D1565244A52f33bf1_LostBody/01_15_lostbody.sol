// SPDX-License-Identifier: MIT
/***
* $$$$$$$$\ $$\                 $$\       $$\     $$\                                   $$\                            $$\     $$$$$$$\                  $$\
* $$  _____|\__|                $$ |      \$$\   $$  |                                  $$ |                           $$ |    $$  __$$\                 $$ |
* $$ |      $$\ $$$$$$$\   $$$$$$$ |       \$$\ $$  /$$$$$$\  $$\   $$\  $$$$$$\        $$ |      $$$$$$\   $$$$$$$\ $$$$$$\   $$ |  $$ | $$$$$$\   $$$$$$$ |$$\   $$\
* $$$$$\    $$ |$$  __$$\ $$  __$$ |        \$$$$  /$$  __$$\ $$ |  $$ |$$  __$$\       $$ |     $$  __$$\ $$  _____|\_$$  _|  $$$$$$$\ |$$  __$$\ $$  __$$ |$$ |  $$ |
* $$  __|   $$ |$$ |  $$ |$$ /  $$ |         \$$  / $$ /  $$ |$$ |  $$ |$$ |  \__|      $$ |     $$ /  $$ |\$$$$$$\    $$ |    $$  __$$\ $$ /  $$ |$$ /  $$ |$$ |  $$ |
* $$ |      $$ |$$ |  $$ |$$ |  $$ |          $$ |  $$ |  $$ |$$ |  $$ |$$ |            $$ |     $$ |  $$ | \____$$\   $$ |$$\ $$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |
* $$ |      $$ |$$ |  $$ |\$$$$$$$ |          $$ |  \$$$$$$  |\$$$$$$  |$$ |            $$$$$$$$\\$$$$$$  |$$$$$$$  |  \$$$$  |$$$$$$$  |\$$$$$$  |\$$$$$$$ |\$$$$$$$ |
* \__|      \__|\__|  \__| \_______|          \__|   \______/  \______/ \__|            \________|\______/ \_______/    \____/ \_______/  \______/  \_______| \____$$ |
*                                                                                                                                                            $$\   $$ |
*                                                                                                                                                            \$$$$$$  |
*                                                                                                                                                            \______/
* For the brave souls who get this far: You are the chosen ones,
* the valiant knights of programming who toil away, without rest,
* fixing our most awful code. To you, true saviors, kings of men,
* I say this: never gonna give you up, never gonna let you down,
* never gonna run around and desert you. Never gonna make you cry,
* never gonna say goodbye. Never gonna tell a lie and hurt you.
*/

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IBayc {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract LostBody is ERC721A, Ownable, Pausable {
    using Strings for uint256;
    using SafeMath for uint256;

    enum EPublicMintStatus {
        CLOSED,
        ALLOWLIST_MINT,
        PUBLIC_MINT
    }

    struct reversemint {
        address reverseaddress;
        uint256 mintquantity;
    }

    string  public baseTokenURI;
    string  public defaultTokenURI;
    string  private _suffix = ".json";
    bytes32 private _merkleRoot = 0x055cd5c12df7ab63adb3ca10e70faa072d50833f01da9aa06399914dbaa72d77;
    uint256 public maxSupply = 8624;
    uint256 public allowlistSalePrice = 0.0061 ether;
    uint256 public publicSalePrice = 0.0066 ether;
    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    address public Bayc = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;

    mapping(address => uint256) public allowlistuserinfo;
    mapping(address => uint256) public publicsaleuserinfo;
    mapping(address => uint256) public baycholderinfo;

    uint256[] public baycholdermintinfo;
    uint256 public publicFreeMintQuantity;
    uint256 public baycHolderMintQuantity;
    uint256 public hasMintQuantityNoBaycMint;
    uint256 public reverseMintQuantity;
    EPublicMintStatus public publicMintStatus;

    constructor(
        string memory _defaultTokenURI
    ) ERC721A("Find Your LostBody", "FYLB") {
        defaultTokenURI = _defaultTokenURI;
        _pause();
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Must from real wallet address");
        _;
    }

    function findlostbody_allowlist(bytes32[] calldata merkleProof, uint256 _quantity) external callerIsUser payable whenNotPaused {
        require(publicMintStatus==EPublicMintStatus.ALLOWLIST_MINT, "Allowlist sale closed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, _merkleRoot, leaf), "Invalid merkle proof");

        require(_quantity > 0, "Invalid quantity");
        require(hasMintQuantityNoBaycMint + _quantity <= 8260, "Exceed supply");
        require(allowlistuserinfo[msg.sender]+_quantity<5,"Exceed allowlist Sale");

        uint256  _remainFreeQuantity = 1;
        if (allowlistuserinfo[msg.sender] > 1) {
            _remainFreeQuantity=0;
        }
        uint256 _needPayPrice =  (_quantity - _remainFreeQuantity) * allowlistSalePrice;

        require(msg.value >= _needPayPrice, "Ether is not enough");
        _safeMint(msg.sender, _quantity);
        allowlistuserinfo[msg.sender]+=_quantity;
        hasMintQuantityNoBaycMint+=_quantity;
    }

    function findlostbody_public(uint256 _quantity) external callerIsUser payable whenNotPaused {
        require(publicMintStatus==EPublicMintStatus.PUBLIC_MINT, "Public sale closed");
        require(_quantity > 0, "Invalid quantity");
        require(hasMintQuantityNoBaycMint + _quantity <= 8260, "Exceed supply");
        require(publicsaleuserinfo[msg.sender]+_quantity<5,"Exceed public Sale");

        uint256  _remainFreeQuantity = 1;
        if (publicsaleuserinfo[msg.sender] > 1) {
            _remainFreeQuantity=0;
        }

        if (publicFreeMintQuantity >= 400){
            _remainFreeQuantity=0;
        }

        uint256 _needPayPrice =  (_quantity - _remainFreeQuantity) * publicSalePrice;

        require(msg.value >= _needPayPrice, "Ether is not enough");
        _safeMint(msg.sender, _quantity);
        publicsaleuserinfo[msg.sender]+=_quantity;
        publicFreeMintQuantity += _quantity;
        hasMintQuantityNoBaycMint+=_quantity;
    }


    function findlostbody_baycmint(uint256 _tokenid) external callerIsUser payable whenNotPaused {
        require(publicMintStatus==EPublicMintStatus.PUBLIC_MINT || publicMintStatus==EPublicMintStatus.ALLOWLIST_MINT, "Baycholder sale closed");
        require(baycHolderMintQuantity <= 24 , "Exceed supply");
        require(baycholderinfo[msg.sender] <= 1 , "The address can only be cast once");
        address baycowner = IBayc(Bayc).ownerOf(_tokenid);
        require(baycowner==msg.sender, "This address is not the holder of this token");
        baycholderinfo[msg.sender]+= 1;
        baycHolderMintQuantity += 1;
        baycholdermintinfo.push(_tokenid);
        _safeMint(msg.sender, 1);
    }


    function findlostbody_reversemint(reversemint[] memory _reversemintinfos) external callerIsUser payable whenNotPaused {
        require(publicMintStatus==EPublicMintStatus.PUBLIC_MINT || publicMintStatus==EPublicMintStatus.ALLOWLIST_MINT, "Marketing campaign  sale closed");
        for (uint256 i=0;i<_reversemintinfos.length;i++){
            require(reverseMintQuantity+_reversemintinfos[i].mintquantity <= 340 , "Exceed supply");
            reverseMintQuantity+=_reversemintinfos[i].mintquantity;
            _safeMint(_reversemintinfos[i].reverseaddress, _reversemintinfos[i].mintquantity);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return
        bytes(currentBaseURI).length > 0 ? string(
            abi.encodePacked(
                currentBaseURI,
                tokenId.toString(),
                _suffix
            )
        ) : defaultTokenURI;
    }


    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setDefaultURI(string calldata _defaultURI) external onlyOwner {
        defaultTokenURI = _defaultURI;
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    function setPublicMintStatus(uint256 status)external onlyOwner{
        publicMintStatus = EPublicMintStatus(status);
    }

    function setPublicPrice(uint256 mintprice)external onlyOwner{
        publicSalePrice = mintprice;
    }


    function openMint() public onlyOwner {
        _unpause();
    }

    function closeMint() public onlyOwner {
        _pause();
    }

    function withdrawMoney() external onlyOwner  {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function isApprovedForAll(address owner, address operator)
    public
    view
    override
    returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        return proxyRegistryAddress == operator || address(proxyRegistry.proxies(owner)) == operator || super.isApprovedForAll(owner, operator);
    }

}

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}