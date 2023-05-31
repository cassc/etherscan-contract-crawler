// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "../Pina/token/IDollar.sol";

interface DontDieMemePool {
    function mint(address account, uint256 amount) external;
}

contract MEME1155 is
    AccessControlEnumerable,
    ERC2981,
    ERC1155,
    Ownable
{
    using SafeMath for uint256;
    using Strings for uint256;
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;
    string internal baseTokenURI;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant JUICING_ROLE = keccak256("JUICING_ROLE");
    
    address public constant dollar = address(0x02814F435dD04e254Be7ae69F61FCa19881a780D);
    address public constant dontDieMemePool = address(0xe0bE1793539378cb87b6d4217E7878d53567bcfb);

    // address public constant dollar = address(0xB8e299BC7370d1cd7e66809Ad89346C97505De70);
    // address public constant dontDieMemePool = address(0xA51F467e2Dbb4ae45971886dEF98C942f9b65e52);

    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => uint256) public tokenMaxSupply;
    mapping(uint256 => uint256) public lockedPina;

    uint256 public currentTokenID;

    constructor(
        string memory _name,
        string memory _symbol,
        address payable royaltyReceiver
    ) ERC1155("https://api.dontdiememe.com/nft/artist/1155/{id}") {
        name = _name;
        symbol = _symbol;
        _setDefaultRoyalty(royaltyReceiver, 500);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }

    function maxSupply(uint256 _id) public view returns (uint256) {
        return tokenMaxSupply[_id];
    }

    function _getNextTokenID() internal view returns (uint256 tokenID){
        return currentTokenID.add(1);
    }

    function _incrementTokenId() internal{
        currentTokenID = currentTokenID.add(1);
    }

    /* minter role */
    function create(uint256 _maxSupply) external onlyRole(MINTER_ROLE) returns (uint256 tokenId) {
        uint256 tokenID = _getNextTokenID();
        _incrementTokenId();
        tokenSupply[tokenID] = 0;
        tokenMaxSupply[tokenID] = _maxSupply;
        return tokenID;
    }

    function setLockedPina(uint256 _tokenID, uint256 _lockedPina) external onlyRole(DEFAULT_ADMIN_ROLE) {
        lockedPina[_tokenID] = _lockedPina;
    }

    function setLockedPina(uint256[] calldata _tokenID, uint256[] calldata _lockedPina) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 n = _tokenID.length;
        for(uint256 i = 0; i < n; ++i){
            lockedPina[_tokenID[i]] = _lockedPina[i];
        }
    }

    function mint(address _to, uint256 _tokenID) external onlyRole(MINTER_ROLE) returns (uint256){
        require(
            tokenSupply[_tokenID] < tokenMaxSupply[_tokenID],
            "Max supply reached"
        );

        // burn pina
        uint256 pina = lockedPina[_tokenID];
        if(pina > 0) {
            DontDieMemePool(dontDieMemePool).mint(address(this), pina);
            IDollar(dollar).burn(pina);
        }
        // mint nft
        _mint(_to, _tokenID, 1, "");
        tokenSupply[_tokenID] = tokenSupply[_tokenID].add(1);
        return _tokenID;
    }

    function redeem(uint256 _tokenID, uint256 _amount) external {
        burn(msg.sender, _tokenID, _amount);

        // mint pina
        uint256 pina = lockedPina[_tokenID];
        if(pina > 0) {
            IDollar(dollar).mint(msg.sender, pina.mul(_amount));
        }
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burn(account, id, value);
    }

    function _baseURI() internal view returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseTokenURI = _baseTokenURI;
    }

    function uri(uint256 _tokenid)
        public
        view
        override
        returns (string memory)
    {
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _tokenid.toString()))
                : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC2981, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /*
        juicing 
    */
    mapping(uint256 => uint256) private juicingStarted;
    mapping(uint256 => uint256) private juicingTaskId;

    event Juiced(uint256 indexed tokenId, uint256 indexed taskId);

    event UnJuiced(uint256 indexed tokenId, uint256 indexed taskId);

    function juicingStatus(uint256 tokenId)
        external
        view
        returns (
            bool juicing,
            uint256 start,
            uint256 task
        )
    {
        start = juicingStarted[tokenId];
        task = juicingTaskId[tokenId];
        if (start != 0) {
            juicing = true;
        } else {
            juicing = false;
        }
    }

    function _beforeTokenTransfer(
        address,
        address,
        address,
        uint256[] memory ids,
        uint256[] memory,
        bytes memory
    ) internal virtual override {
        for (uint256 i = 0; i < ids.length; ++i)
            require(juicingStarted[ids[i]] == 0, "MEME1155: juicing");
    }

    function toggleJuicing(
        uint256 tokenId,
        bool juicing,
        uint256 taskId
    ) internal {
        if (juicing) {
            juicingStarted[tokenId] = block.timestamp;
            juicingTaskId[tokenId] = taskId;
            emit Juiced(tokenId, taskId);
        } else {
            require(taskId == juicingTaskId[tokenId], "MEME1155: wrong taskid");
            juicingStarted[tokenId] = 0;
            juicingTaskId[tokenId] = 0;
            emit UnJuiced(tokenId, taskId);
        }
    }

    function toggleJuicing(
        uint256[] calldata tokenIds,
        bool juicing,
        uint256 taskId
    ) external onlyRole(JUICING_ROLE) {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            toggleJuicing(tokenIds[i], juicing, taskId);
        }
    }

}