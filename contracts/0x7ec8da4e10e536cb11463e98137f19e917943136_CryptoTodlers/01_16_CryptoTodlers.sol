// contracts/CryptoTodlers.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./INCT.sol";

contract CryptoTodlers is ERC721Enumerable, Ownable {
    using Strings  for uint256;
    using SafeMath for uint256;

    // data structure defining a baby parents couple of crypto hodlers
    struct CryptoParents {
        uint256 parent1;
        uint256 parent2;
    }

    // The name change price
    uint256 public constant NAME_CHANGE_PRICE = 200 * (10 ** 18);

    // mapping babyId to name
    mapping (uint256 => string) private _tokenName;

    // mapping name to used flag
    mapping (string => bool) private _nameReserved;

    // mapping baby to parents. Parents are 0-based.
    // shall use _exists(babyId) to verify babyId exists and the parents key are valid
    mapping (uint256 => CryptoParents) private _babyToParentsMap;

    // mapping parent to babyId. Baby id is 1-based, so 0 babyId means not available
    mapping (uint256 => uint256) private _parentToBabyMap;

    // base URI
    string private _rootURI;

    // flag to signal if mint is active or not
    bool _mintIsActive;

    // the crypto hodlers pointer
    IERC721Enumerable private _nft;
    // the NCT contract pointer
    INCT private _nct;

    // Events
    event NameChange (uint256 indexed tokenIdx, string newName);


    /**
     * @dev Constructor that stores the NCT pointer
     * The parameters are:
     * nftAddress - address of the CryptoHodlers
     * nctAddress - address of the NCT contract
     */
    constructor(address nftAddress, address nctAddress) ERC721("CryptoTodlers", "TODLERS") {
        _mintIsActive = false;
        _nft = IERC721Enumerable(nftAddress);
        _nct = INCT(nctAddress);
    }

    /**
     * @dev Returns name of the NFT at index.
     */
    function tokenNameByIndex(uint256 index) public view returns (string memory) {
        return _tokenName[index];
    }

    /**
     * @dev Returns if the name has been reserved.
     */
    function isNameReserved(string memory nameString) public view returns (bool) {
        return _nameReserved[toLower(nameString)];
    }

    /**
     * @dev Changes the name for Hashmask tokenId
     */
    function changeName(uint256 tokenId, string memory newName) public {
        address owner = ownerOf(tokenId);

        require(_msgSender() == owner, "ERC721: caller is not the owner");
        require(validateName(newName) == true, "Not a valid new name");
        require(sha256(bytes(newName)) != sha256(bytes(_tokenName[tokenId])), "New name is same as the current one");
        require(isNameReserved(newName) == false, "Name already reserved");

        _nct.transferFrom(msg.sender, address(this), NAME_CHANGE_PRICE);

        // If already named, dereserve old name
        if (bytes(_tokenName[tokenId]).length > 0) {
            toggleReserveName(_tokenName[tokenId], false);
        }
        toggleReserveName(newName, true);
        _tokenName[tokenId] = newName;
        _nct.burn(NAME_CHANGE_PRICE);
        emit NameChange(tokenId, newName);
    }

    /**
    * @dev Flip mint state
    */
    function flipMintState() public onlyOwner() {
        _mintIsActive = !_mintIsActive;
    }

    /**
    * @dev Returns true if  mint is active
    */
    function isMintActive() public view returns (bool) {
        return _mintIsActive;
    }

    /**
    * @dev Returns the parents ids of a baby
    */
    function getParentsId(uint256 tokenId) public view returns (uint256, uint256) {
        require(_exists(tokenId), "token ID not valid");

        return (_babyToParentsMap[tokenId].parent1, _babyToParentsMap[tokenId].parent2);
    }

    /**
    * @dev Returns the baby id from the parentId, 0 if does not exist
    */
    function getBabyId(uint256 parentId) public view returns (uint256) {
        return _parentToBabyMap[parentId];
    }

    /**
   * @dev Returns the number of parents without a baby for a specific owner
   */
    function getNumParentsWithoutBaby(address owner) public view returns (uint256) {

        uint256 toRemove  = 0;
        uint256 numTokens = _nft.balanceOf(owner);

        for(uint256 i = 0; i < numTokens; i++){
            if(hasParentOneBaby(_nft.tokenOfOwnerByIndex(owner, i))){
                toRemove += 1;
            }
        }

        return numTokens - toRemove;
    }

    /**
   * @dev Returns the i-th parentID that do not have an baby, owned by the given wallet
   */
    function parentWithoutBabyByIndex(address owner, uint256 index) public view returns (uint256) {

        uint256 numParentsCanMint = getNumParentsWithoutBaby(owner);

        require(index < numParentsCanMint, "index out of value");

        uint256 k = 0;
        uint256 numAllTokens = _nft.balanceOf(owner);

        for(uint256 i = 0; i < numAllTokens; i++){
            uint256 pid = _nft.tokenOfOwnerByIndex(owner, i);

            if(!hasParentOneBaby(pid)){
                k += 1; // the k-th parent that can be selected
            }

            // the k-th is the one we are looking for
            if(k > index){
                return pid;
            }
        }

        revert("no parent found");
    }

  /**
  * @dev Returns the i-th parentID that do not have an baby, owned by the given wallet
  */
    function getNextAvailableParent(address owner, uint256 numAllTokens, uint256 index) internal view returns (uint256, uint256) {

        for(uint256 i = index; i < numAllTokens; i++){
            uint256 pid = _nft.tokenOfOwnerByIndex(owner, i);

            if(!hasParentOneBaby(pid)){
                return (pid, i + 1);
            }
        }

        revert("no parent found");
    }

    /**
    * @dev Returns true if the parent has a baby
    */
    function hasParentOneBaby(uint256 parentId) public view returns (bool) {
        return _parentToBabyMap[parentId] != 0;
    }

    /**
    * @dev Internal function to mint a new token using 'parent1' and 'parent2'
    */
    function _mintNFT(uint256 parent1, uint256 parent2) internal {
        require(!hasParentOneBaby(parent1), "parent already has a baby");
        require(!hasParentOneBaby(parent2), "parent already has a baby");

        // the first token will have id set to 1
        uint256 newTokenId = totalSupply() + 1;

        _safeMint(msg.sender, newTokenId);

        CryptoParents memory parents = CryptoParents(parent1, parent2);

        _babyToParentsMap[newTokenId] = parents;
        _parentToBabyMap[parent1]     = newTokenId;
        _parentToBabyMap[parent2]     = newTokenId;

    }

    /**
     * @dev Mint a new token using 'parent1' and 'parent2'
     */
    function mintNFT(uint256 parent1, uint256 parent2) public {
        require(_mintIsActive,                         "mint is not active");
        require(_nft.ownerOf(parent1) == _msgSender(), "caller is not the parent owner");
        require(_nft.ownerOf(parent2) == _msgSender(), "caller is not the parent owner");
        require(parent1 != parent2,                    "same parent");

        _mintNFT(parent1, parent2);
    }


    /**
      * @dev Mint 'numTodlers' new tokens
    */
    function bulkMint(uint256 numTodlers) public {
        require(_mintIsActive,  "mint is not active");
        require(numTodlers > 0, "numTodlers not valid");

        uint256 p1;
        uint256 p2;
        uint256 k = 0;
        uint256 numParents   = getNumParentsWithoutBaby(_msgSender());
        uint256 numAllTokens = _nft.balanceOf(_msgSender());

        require(numParents >= numTodlers.mul(2), "not enough parents");

        for(uint256 i = 0; i < numTodlers; i++){

            (p1, k) = getNextAvailableParent(_msgSender(), numAllTokens, k);
            (p2, k) = getNextAvailableParent(_msgSender(), numAllTokens, k);

            _mintNFT(p1, p2);
        }
    }


    /**
     * @dev Reserves the name if isReserve is set to true, de-reserves if set to false
     */
    function toggleReserveName(string memory str, bool isReserve) internal {
        _nameReserved[toLower(str)] = isReserve;
    }

    /**
     * @dev Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
     */
    function validateName(string memory str) public pure returns (bool){
        bytes memory b = bytes(str);
        if(b.length < 1) return false;
        if(b.length > 25) return false; // Cannot be longer than 25 characters
        if(b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if(!(char >= 0x30 && char <= 0x39) && //9-0
               !(char >= 0x41 && char <= 0x5A) && //A-Z
               !(char >= 0x61 && char <= 0x7A) && //a-z
               !(char == 0x20) //space
            ) return false;


            lastChar = char;
        }

        return true;
    }

    /**
     * @dev Converts the string to lowercase
     */
    function toLower(string memory str) public pure returns (string memory){
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function setBaseURI(string memory uri) external onlyOwner() {
        _rootURI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _rootURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),           "Token ID not valid");
        require(bytes(_rootURI).length > 0, "Base URI not yet set");

        // concatenate the baseURI and tokenId (via abi.encodePacked).
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }
}