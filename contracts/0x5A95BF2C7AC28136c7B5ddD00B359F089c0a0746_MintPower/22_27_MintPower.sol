// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./Super1155.sol";

contract MintPower is ERC721, ERC1155Receiver, Ownable, Pausable, ReentrancyGuard, DefaultOperatorFilterer {
    string public baseURI;

    address public immutable token;
    address public scoresContract;

    bytes32 public merkleRoot;
    bytes32 public superMerkleRoot;


    // burnPoints => mintPower
    mapping(uint256 => uint256) public mintPowerConfig;

    // tokenId => mintPower
    mapping(uint256 => uint256) public mintPowers;
    mapping(address => uint256) private superAllowlistClaimed;
    

    uint256 public totalSupply;
    uint256 public totalBurned;
    
    
    bool public ActiveAllowlistMint = false;
    bool public ActiveSuperAllowlistMint = false;

    struct MintPowerstruct {
    uint256 id;
    uint256 power;
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory uri,
        address _token
    ) ERC721(name, symbol) {
        baseURI = uri;
        token = _token;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setScoresContract(address _scoresContract) external onlyOwner {
        scoresContract = _scoresContract;
    }

    function setSuperMerkleRoot(bytes32 _superMerkleRoot) external onlyOwner {
        superMerkleRoot = _superMerkleRoot;
    }

    function setMintState(bool _ActiveAllowlistMint,bool _ActiveSuperAllowlistMint) external onlyOwner {
        (ActiveAllowlistMint, ActiveSuperAllowlistMint) = (_ActiveAllowlistMint, _ActiveSuperAllowlistMint);
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function updateMintPowerConfigSingle(
        uint256 burnPoints,
        uint256 mintPower
    ) external onlyOwner {
        mintPowerConfig[burnPoints] = mintPower;
    }

    function updateMintPowerConfigMulti(
        uint256[] memory burnPoints,
        uint256[] memory mintPower
    ) external onlyOwner {
        require(burnPoints.length == mintPower.length, "Invalid Params");

        for (uint i = 0; i < burnPoints.length; i++) {
            mintPowerConfig[burnPoints[i]] = mintPower[i];
        }
    }

    function mintNFT(uint256 amount) external whenNotPaused nonReentrant {
        require(mintPowerConfig[amount] != 0, "Invalid Amount");

        Super1155(token).safeTransferFrom(
            msg.sender,
            address(this),
            0,
            amount,
            ""
        );
        Super1155(token).burn(amount);
        addTokenIdToOwner(uint32(totalSupply), msg.sender);
        _mint(msg.sender, totalSupply);
        mintPowers[totalSupply] = mintPowerConfig[amount];
        totalSupply += 1;
    }

    function mintNFT_Admin(uint256 amount) external onlyOwner nonReentrant {
        require(mintPowerConfig[amount] != 0, "Invalid Amount");

        addTokenIdToOwner(uint32(totalSupply), msg.sender);
        _mint(msg.sender, totalSupply);
        mintPowers[totalSupply] = mintPowerConfig[amount];
        totalSupply += 1;
    }

    function mintNFT_Allowlist(uint256 amount, bytes32[] calldata merkleProof) external nonReentrant {
        require(ActiveAllowlistMint, "Mint is not active.");
        require(mintPowerConfig[amount] != 0, "Invalid Amount");

        bytes32 leaf = keccak256(abi.encode(msg.sender));
        require( MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid proof");

        Super1155(token).safeTransferFrom(
            msg.sender,
            address(this),
            0,
            amount,
            ""
        );
        Super1155(token).burn(amount);
        addTokenIdToOwner(uint32(totalSupply), msg.sender);
        _mint(msg.sender, totalSupply);
        mintPowers[totalSupply] = mintPowerConfig[amount];
        totalSupply += 1;
    }

    function mintNFT_SuperAllowlist(uint256 amount, bytes32[] calldata merkleProof) external nonReentrant {
        require(ActiveSuperAllowlistMint, "Mint is not active.");
        require(superAllowlistClaimed[msg.sender] < amount, "Already claimed.");
 
        uint256 claimingAmount = amount - superAllowlistClaimed[msg.sender];
        require(mintPowerConfig[claimingAmount] != 0, "Invalid Amount");

        bytes32 leaf = keccak256(abi.encode(msg.sender, amount));
        require( MerkleProof.verify(merkleProof, superMerkleRoot, leaf), "Invalid proof");
       
        superAllowlistClaimed[msg.sender] = amount;

        addTokenIdToOwner(uint32(totalSupply), msg.sender);
        _mint(msg.sender, totalSupply);
        mintPowers[totalSupply] = mintPowerConfig[claimingAmount];
        totalSupply += 1;
    }

    function combine(uint256[] memory tokenIds) external nonReentrant {
        require(ownerOf(tokenIds[0]) == msg.sender, "Not Authorized");

        uint256 sum = 0;
        for (uint i = 1; i < tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == msg.sender, "Not Authorized");

            sum += mintPowers[tokenIds[i]];
            mintPowers[tokenIds[i]] = 0;
            removeTokenIdFromOwner(uint32(tokenIds[i]), msg.sender);
            _burn(tokenIds[i]);
        }

        totalBurned += tokenIds.length - 1;
        mintPowers[tokenIds[0]] += sum;
    }

    function reducePower(uint256 tokenId, uint256 reduceAmount) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender || scoresContract == msg.sender , "Not Authorized");
       
        if(mintPowers[tokenId] > 0 && mintPowers[tokenId] >= reduceAmount) {
           mintPowers[tokenId] -= reduceAmount;
        } 
        
        if (mintPowers[tokenId] == 0) {
           removeTokenIdFromOwner(uint32(tokenId), ownerOf(tokenId));
           totalBurned += 1;
           _burn(tokenId);
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC1155Receiver) returns (bool) {
        return
            ERC1155Receiver.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    /** These are replacement methods for ERC721Enum functionality (in order to spare gas/bytes). */

    mapping(address => uint32[]) internal idsByOwner;
    mapping(uint32 => uint32) internal ownerIndexById;

    function addTokenIdToOwner(uint32 tokenId, address owner) internal { 
        ownerIndexById[tokenId] = uint32(idsByOwner[owner].length);
        idsByOwner[owner].push(tokenId);
    }

    function removeTokenIdFromOwner(uint32 tokenId, address owner) internal returns(bool) {
        uint32[] storage ids = idsByOwner[owner];
        uint256 balance = ids.length;

        uint32 index = ownerIndexById[tokenId];
        if (ids[index] != tokenId) {
        return false;
        }
        uint32 movingId = ids[index] = ids[balance - 1];
        ownerIndexById[movingId] = index;
        ids.pop();

        return true;
    }

    function getAllTokenIdsOfOwner(address owner) public view returns (uint32[] memory ids) {
        ids = idsByOwner[owner];
    }

    function balanceOfOwner(address owner) public view returns(uint balance) {
        balance = idsByOwner[owner].length;
    }

    /** Implement tracking of marketplace transfers.
    * @param from token transfer from
    * @param to token transfer to
    * @param tokenId token being transferred
    * This function could be modified to handle the mint/burnt transfers too, 
        but we handle these cases from mint() and burn() for now.
    */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (from == address(0)) { 
        } else if (to == address(0)) {
        } else {
        removeTokenIdFromOwner(uint32(tokenId), from);
        addTokenIdToOwner(uint32(tokenId), to);
        }
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function getById(uint256 tokenId) public view returns (uint256) {
        return mintPowers[tokenId];
    }

    function getByOwner(address owner) public view returns (MintPowerstruct[] memory mp) {
        uint32[] storage ids = idsByOwner[owner];
        mp = new MintPowerstruct[](ids.length);

        for (uint ix = 0; ix < ids.length; ix++) {
        uint32 id = ids[ix];
        mp[ix].id = id;
        mp[ix].power = mintPowers[id];
        }
    }

    string private jsonStart = 'data:application/json;base64,';
    string private jsonEnd = '"}';
    string internal svgHead = '\
    <svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 1120 760">\
    <style>\
        text {\
        font-family:Roboto-Regular,Roboto;\
        }\
    </style>\
    ';

    function getAttributes(uint256 tokenId,uint256 power) internal pure returns (string memory out) {
   
    out = string(abi.encodePacked(
      '{"name":"MPT #', Strings.toString(tokenId),
      '","background_color":"202426"',
      ',"attributes":[{"trait_type":"Power","value":"', Strings.toString(power), '"}],"image": "data:image/svg+xml;base64,'
    ));
    }

    function genSVG(uint256 power) internal view returns (string memory) {
  
    return string(abi.encodePacked(
      svgHead,
      '<rect x="0" y="0" width="1120" height="760" style="fill:#ffcd00"/>',
      '<text x="345" y="400" font-size="10.4em" style="fill:black" >MP ', Strings.toString(power), '</text>' ,

      '<rect x="340" y="600" width="60" height="60" style="fill:#ffffff"/>',
      '<rect x="410" y="600" width="60" height="60" style="fill:#ffe642"/>',
      '<rect x="480" y="600" width="60" height="60" style="fill:#df2020"/>',
      '<rect x="550" y="600" width="60" height="60" style="fill:#4cb2e6"/>',
      '<rect x="620" y="600" width="60" height="60" style="fill:#ff7b00"/>',
      '<rect x="690" y="600" width="60" height="60" style="fill:#5ED723"/>',
      '</svg>'
    ));
  }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
    uint256 power = mintPowers[tokenId];

    return string(abi.encodePacked(
    jsonStart, 
    Base64.encode(bytes(string(
        abi.encodePacked(
        getAttributes(tokenId,power),
        Base64.encode(bytes(genSVG(power))),
        jsonEnd
        )
    )))
    ));
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>

library Base64 {
  bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  /// @notice Encodes some bytes to the base64 representation
  function encode(bytes memory data) internal pure returns (string memory) {
    uint256 len = data.length;
    if (len == 0) return "";

    uint256 encodedLen = 4 * ((len + 2) / 3);

    bytes memory result = new bytes(encodedLen + 32);
    bytes memory table = TABLE;

    assembly {
      let tablePtr := add(table, 1)
      let resultPtr := add(result, 32)
      for {
        let i := 0
      } lt(i, len) {
      } {
        i := add(i, 3)
        let input := and(mload(add(data, i)), 0xffffff)
        let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
        out := shl(224, out)
        mstore(resultPtr, out)
        resultPtr := add(resultPtr, 4)
      }
      switch mod(len, 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }
      mstore(result, encodedLen)
    }
    return string(result);
  }
}