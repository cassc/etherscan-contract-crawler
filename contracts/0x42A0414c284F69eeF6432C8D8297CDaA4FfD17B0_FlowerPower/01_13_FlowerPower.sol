//SPDX-License-Identifier: MIT
/*                                                                                                                                                                     _                   _          _               _          _              _          _      
 ________   .---.       ,-----.    .--.      .--.    .-''-.  .-------.            .-------.     ,-----.    .--.      .--.    .-''-.  .-------.     
|        |  | ,_|     .'  .-,  '.  |  |_     |  |  .'_ _   \ |  _ _   \           \  _(`)_ \  .'  .-,  '.  |  |_     |  |  .'_ _   \ |  _ _   \    
|   .----',-./  )    / ,-.|  \ _ \ | _( )_   |  | / ( ` )   '| ( ' )  |           | (_ o._)| / ,-.|  \ _ \ | _( )_   |  | / ( ` )   '| ( ' )  |    
|  _|____ \  '_ '`) ;  \  '_ /  | :|(_ o _)  |  |. (_ o _)  ||(_ o _) /           |  (_,_) /;  \  '_ /  | :|(_ o _)  |  |. (_ o _)  ||(_ o _) /    
|_( )_   | > (_)  ) |  _`,/ \ _/  || (_,_) \ |  ||  (_,_)___|| (_,_).' __         |   '-.-' |  _`,/ \ _/  || (_,_) \ |  ||  (_,_)___|| (_,_).' __  
(_ o._)__|(  .  .-' : (  '\_/ \   ;|  |/    \|  |'  \   .---.|  |\ \  |  |        |   |     : (  '\_/ \   ;|  |/    \|  |'  \   .---.|  |\ \  |  | 
|(_,_)     `-'`-'|___\ `"/  \  ) / |  '  /\  `  | \  `-'    /|  | \ `'   /        |   |      \ `"/  \  ) / |  '  /\  `  | \  `-'    /|  | \ `'   / 
|   |       |        \'. \_/``".'  |    /  \    |  \       / |  |  \    /         /   )       '. \_/``".'  |    /  \    |  \       / |  |  \    /  
'---'       `--------`  '-----'    `---'    `---`   `'-..-'  ''-'   `'-'          `---'         '-----'    `---'    `---`   `'-..-'  ''-'   `'-'                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
*/

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract FlowerPower is ERC721A, Ownable {
    using Strings for uint256;

  uint256 public constant MAX_SUPPLY = 3333;
  uint256 public constant MAX_MINTS = 1;
  uint256 public constant PUBLIC_PRICE = 0.033 ether;
  uint256 public constant PRESALE_PRICE = 0.0 ether;

  bool public isPresaleActive = false;
  bool public isPublicSaleActive = false;
  bool public revealed = false;

  bytes32 public merkleRoot;
  mapping(address => uint256) public purchaseTxs;
  mapping(address => uint256) private _allowed;

  string private _baseURIextended;
  string public notRevealedUri;

  address[] private mintPayees = [
    0x1F3057188A5d55E935C32A1942512BE29064F2d9
  ];

  constructor() ERC721A("FlowerPower", "FP") {}

  function preSaleMint(bytes32[] calldata _proof, uint256 nMints)
    external
    payable
  {
    require(msg.sender == tx.origin, "Can't mint through another contract");
    require(isPresaleActive, "Presale not active");

    bytes32 node = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_proof, merkleRoot, node), "Not on allow list");
    require(nMints <= MAX_MINTS, "Exceeds max token purchase");
    require(totalSupply() + nMints <= MAX_SUPPLY, "Mint exceeds total supply");
    require(PRESALE_PRICE * nMints <= msg.value, "Sent incorrect ETH value");
    require(_allowed[msg.sender] + nMints <= MAX_MINTS, "Exceeds mint limit");

    // Keep track of mints for each address
    if (_allowed[msg.sender] > 0) {
      _allowed[msg.sender] = _allowed[msg.sender] + nMints;
    } else {
      _allowed[msg.sender] = nMints;
    }

    _safeMint(msg.sender, nMints);
  }

  function mint(uint256 nMints) external payable {
    require(msg.sender == tx.origin, "Can't mint through another contract");
    require(isPublicSaleActive, "Public sale not active");
    require(nMints <= MAX_MINTS, "Exceeds max token purchase");
    require(totalSupply() + nMints <= MAX_SUPPLY, "Mint exceeds total supply");
    require(PUBLIC_PRICE * nMints <= msg.value, "Sent incorrect ETH value");

    _safeMint(msg.sender, nMints);
  }

	function reveal() external onlyOwner {
		revealed = true;
	}

  function withdrawAll() external onlyOwner {
    require(address(this).balance > 0, "No funds to withdraw");
    _withdraw(mintPayees[0], address(this).balance);
  }

  function reserveMint(uint256 nMints, uint256 batchSize) external onlyOwner {
    require(totalSupply() + nMints <= MAX_SUPPLY, "Mint exceeds total supply");
    require(nMints % batchSize == 0, "Can only mint a multiple of batchSize");

    for (uint256 i = 0; i < nMints / batchSize; i++) {
      _safeMint(msg.sender, batchSize);
    }
  }

  function setBaseURI(string calldata baseURI_) external onlyOwner {
    _baseURIextended = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIextended;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function togglePresale() external onlyOwner {
    isPresaleActive = !isPresaleActive;
  }

  function togglePublicSale() external onlyOwner {
    isPublicSaleActive = !isPublicSaleActive;
  }

  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{value: _amount}("");
    require(success, "Transfer failed.");
  }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }
    
    function setNotRevealedURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

  receive() external payable {}
}