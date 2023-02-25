//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Sell_item2 is ERC1155, Ownable {
    using Address for address;
    using Strings for string;

    struct Token {
        uint128 maxSupply;
        uint128 supply;
        bytes32 name;
    }

    string baseURI;
    uint256 public tokenCount;

    mapping(uint256 => Token) public tokens;
    mapping(address => mapping(uint256 => uint8)) public whitelisted;

    event Mint(address indexed _to, uint256 _tokenId);
    event Burn(address indexed _from, uint256 _tokenId);
    event NewWhitelisted(uint256 _tokenId, address _address);
    event CreateToken(uint256 _tokenId, uint256 _tokenMaxSupply);

    error NullAddress();
    error NotWhitelisted(address);
    error NullAmount();
    error MaxSupplyReached();
    error TokenDoesNotExist(uint256);

    modifier onlyWhitelisted(uint256 _tokenId) {
        if(whitelisted[msg.sender][_tokenId] == 0) revert NotWhitelisted(msg.sender);
        _;
    }


    constructor(string memory _baseURI) ERC1155("https://cloud.cdn/{id}.json")
    {
        baseURI = _baseURI;
    }

    /*//////////////////////////////////////////////////////////////
                              TOKEN LOGIC
    //////////////////////////////////////////////////////////////*/
    function createToken(uint128 _maxSupply, bytes32 _name) public onlyOwner {
        uint256 tokenId = tokenCount + 1;
        tokens[tokenId] = Token({
            maxSupply: _maxSupply,
            supply: 0, 
            name: _name
        });
        tokenCount = tokenId;
    }

    function setTokenMaxSupply(uint256 _tokenId, uint128 _maxSupply) external onlyOwner {
      if (exist(_tokenId) == false) revert TokenDoesNotExist(_tokenId);
        tokens[_tokenId].maxSupply = _maxSupply;
    }

    function setTokenName(uint256 _tokenId, bytes32 _name) external onlyOwner {
      if (exist(_tokenId) == false) revert TokenDoesNotExist(_tokenId);
        tokens[_tokenId].name = _name;
    }

    function getTokenInfo(uint256 _tokenId) external view returns (bytes32, uint128, uint128) {
      if (exist(_tokenId) == false) revert TokenDoesNotExist(_tokenId);
        Token storage token = tokens[_tokenId];
        return (token.name, token.maxSupply, token.supply);
}


    /*//////////////////////////////////////////////////////////////
                            WHITELIST LOGIC
    //////////////////////////////////////////////////////////////*/
    function addWhitelisted(uint256 _tokenId, address[] memory newWhitelisted) external onlyOwner {
      if (exist(_tokenId) == false) revert TokenDoesNotExist(_tokenId);
        for(uint i = 0; i < newWhitelisted.length; i++) {
            if (newWhitelisted[i] == address(0)) revert NullAddress();
            whitelisted[newWhitelisted[i]][_tokenId]++;
            emit NewWhitelisted(_tokenId, newWhitelisted[i]);
        }
    }

    function isWhitelisted(uint256 _tokenId, address _address) public onlyOwner view returns (uint8)  {
      if (exist(_tokenId) == false) revert TokenDoesNotExist(_tokenId);
      return whitelisted[_address][_tokenId];
    }

    function delWhitelisted(uint256 _tokenId, address[] memory thisWhitelisted) external onlyOwner {
      if (exist(_tokenId) == false) revert TokenDoesNotExist(_tokenId);
        for(uint i = 0; i < thisWhitelisted.length; i++) {
            if (thisWhitelisted[i] == address(0)) revert NullAddress();
            whitelisted[thisWhitelisted[i]][_tokenId]--;
        }
    }

    /*//////////////////////////////////////////////////////////////
                               MINT LOGIC
    //////////////////////////////////////////////////////////////*/
    function mint(uint256 _tokenId) external onlyWhitelisted(_tokenId) {
      if (exist(_tokenId) == false) revert TokenDoesNotExist(_tokenId);
        Token storage token = tokens[_tokenId];
        if (token.supply == token.maxSupply) revert MaxSupplyReached();

        ++tokens[_tokenId].supply;
        whitelisted[msg.sender][_tokenId]--;
        _mint(msg.sender, _tokenId, 1, "");
        emit Mint(msg.sender, _tokenId);
    }

    function burn(uint256 id, uint256 amount) external {
        _burn(msg.sender, id, amount);
        emit Burn(msg.sender, id);
    }

    function exist(uint256 _tokenId) public view returns(bool) {
    return (tokens[_tokenId].name != "");
    }

    function setBaseUrl(string memory _baseUrl) public onlyOwner {
        baseURI = _baseUrl;
    }

    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    baseURI,
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }   
}