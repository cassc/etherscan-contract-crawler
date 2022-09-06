// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "solmate/tokens/ERC1155.sol";
import "solmate/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./IRenderer.sol";
import "./Errors.sol";

/*
.                            .

          :=+*#**+**=         
        =*%%%##%%%@%*+=       
     .=#%%%@@%%%%#+++++#+.    
    .%%@@@@@@%#+==+=+#@%*:    
    -%%@@@%*+==++*##@@#+*=    
    [email protected]@%#++++*#%@@%%*++#%#.   
    .#**##%@@@@@%*++*%%%#=    
    +#%@@@@@%#*+*#%%%%*+:     
    :=*%##*#%%%%%###*++:      
     .-=*#%%@@%#+***+-.       
          =++==*#+-:    

.                            .      
 */

contract Particles is ERC1155, Ownable, ReentrancyGuard {
  // emitted when new particles get spawned
  event Spawn(
    uint256 indexed tokenId,
    uint256 maxSpawn,
    address minter,
    address renderer,
    string ipfsHash
  );

  struct Particle {
    uint256 spawned;
    uint256 maxSpawn;
    address minter;
    address renderer;
    bytes metadata;
  }

  string public baseURI;
  string public contractURI;

  mapping(uint256 => Particle) public particles;

  string public name = "interface particles";
  string public symbol = "IN][PA";

  constructor(string memory _baseURI, string memory _contractURI) {
    baseURI = _baseURI;
    contractURI = _contractURI;
  }

  function particleExists(uint256 tokenId) public view returns (bool) {
    if (particles[tokenId].maxSpawn != 0) {
      return true;
    }
    return false;
  }

  function spawn(
    uint256 tokenId,
    uint256 maxSpawn,
    address minter,
    address renderer,
    bytes calldata ipfsHash
  ) external onlyOwner {
    if (particleExists(tokenId)) revert Errors.ParticleAlreadyExists();
    if (maxSpawn == 0) revert Errors.ParticleMaxSpawnCannotBeZero();

    particles[tokenId].spawned = 0;
    particles[tokenId].maxSpawn = maxSpawn;
    particles[tokenId].metadata = ipfsHash;
    particles[tokenId].minter = minter;
    particles[tokenId].renderer = renderer;

    emit URI(uri(tokenId), tokenId);
    emit Spawn(tokenId, maxSpawn, minter, renderer, string(ipfsHash));
  }

  function mint(
    address sender,
    uint256 tokenId,
    uint256 editions
  ) public nonReentrant {
    if (tokenId == 0) revert Errors.UnknownParticle();
    if (!particleExists(tokenId)) revert Errors.UnknownParticle();
    if (particles[tokenId].minter != msg.sender) revert Errors.InvalidMinter();
    if (particles[tokenId].spawned + editions > particles[tokenId].maxSpawn)
      revert Errors.MaxSpawnMinted();

    particles[tokenId].spawned += editions;
    _mint(sender, tokenId, editions, "");
  }

  function burn(uint256 tokenId, uint256 editions) public nonReentrant {
    if (tokenId == 0) revert Errors.UnknownParticle();
    if (!particleExists(tokenId)) revert Errors.UnknownParticle();
    if (balanceOf[msg.sender][tokenId] < editions)
      revert Errors.CannotBurnWhatYouDontOwn();

    _burn(msg.sender, tokenId, editions);
  }

  function setContractURI(string calldata _contractURI) public onlyOwner {
    contractURI = _contractURI;
  }

  function setBaseURI(string calldata _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }

  function updateTokenURI(uint256 tokenId, bytes calldata path)
    external
    onlyOwner
  {
    particles[tokenId].metadata = path;
    emit URI(uri(tokenId), tokenId);
  }

  function updateTokenRenderer(uint256 tokenId, address _renderer)
    external
    onlyOwner
  {
    particles[tokenId].renderer = _renderer;
  }

  function uri(uint256 tokenId) public view override returns (string memory) {
    if (particles[tokenId].renderer == address(0)) {
      return string(abi.encodePacked(baseURI, particles[tokenId].metadata));
    }

    IRenderer renderer = IRenderer(particles[tokenId].renderer);
    return renderer.uri(tokenId);
  }

  function maxSupply(uint256 id) public view returns (uint256) {
    return particles[id].maxSpawn;
  }

  function spawned(uint256 id) public view returns (uint256) {
    return particles[id].spawned;
  }

  // just in case someone sends accidental funds or something
  function withdraw(address payable payee) external onlyOwner {
    uint256 balance = address(this).balance;
    (bool sent, ) = payee.call{value: balance}("");
    if (!sent) {
      revert Errors.WithdrawTransfer();
    }
  }
}