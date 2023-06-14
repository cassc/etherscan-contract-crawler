pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//   _,   _,  __  ,  ___,,  ,    ,_   _, ,  ,_   , ,__,   
//  / _  / \,'|_) | ' |  |\ |    |_) / \,\_/'|\  |   /    
// '\_|`'\_/ _|_)'|___|_,|'\|   '| \'\_/, /` |-\'|__/_    
//   _|  '  '       '    '  `    '  `' (_/   '  `  '  `   
//  '                                                     

contract GoblinRoyalz is ERC721A, Ownable {

    //   _, _, ,  , _, ___,_  ,  ,  _,___,_, ,_   
    //  /  / \,|\ |(_,' | |_) |  | / ' | / \,|_)  
    // '\_'\_/ |'\| _)  |'| \'\__|'\_  |'\_/'| \  
    //    `'   '  `'    ' '  `   `   ` ' '   '  ` 
                                           

    uint256 public constant MAX_SUPPLY = 6900;

    bool public isPublicSaleActive = false;
    uint256 public maxPerAddress = 20;
    uint256 public maxPerTx = 20;
    uint256 public mintPrice = 0.0042 ether;

    string public contractURIString = "https://northupcrypto.mypinata.cloud/ipfs/QmbiDiXAMaXm2TAecc89bcDuxgFXUpbWyrz5Yh3ztz4buQ";
    string public baseURI = "https://northupcrypto.mypinata.cloud/ipfs/QmQtY8YdkbwkBZQV9jSXCcEwoChGuh7QhAQ7Nt5WKqd1wZ/";

    constructor() ERC721A("GoblinRoyalz", "GR") {}

    //  , ,  _, ,_   ___,__, ___,  _,,_   _, 
    // |\/| / \,| \,' | '|_,' |   /_,|_) (_, 
    // | `|'\_/_|_/  _|_,|   _|_,'\_'| \  _) 
    // '  ` ' '     '    '  '       `'  `'   
                                                                    
    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not open");
        _;
    }

    modifier mintCompliance(uint256 _amount) {
        require(tx.origin == msg.sender, "No contract minting");
        require(_amount <= maxPerTx, "Too many mints per tx");
        require(totalSupply() + _amount <= MAX_SUPPLY, "Not enough mints left");
        _;
    }

    //  ___,,  , ___,_,,_  ,  , _   ,   
    // ' |  |\ |' | /_,|_) |\ |'|\  |   
    //  _|_,|'\|  |'\_'| \ |'\| |-\'|__ 
    // '    '  `  '   `'  `'  ` '  `  '

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    //  ,_,_   ___,   ,_  ___,_, 
    //  |_)_) ' | \  /'|\' | /_, 
    // '|'| \  _|_,\/` |-\ |'\_  
    //  ' '  `'    '   '  `'   `                   
                                  
    function checkValue(uint256 price) private {
        if (msg.value > price) {
            (bool succ, ) = payable(msg.sender).call{
                value: (msg.value - price)
            }("");
            require(succ, "Transfer failed");
        }
        else if (msg.value < price) {
            revert("Not enough ETH sent");
        }
    }

    //   _, ,  ,,  ,  _,,_   
    //  / \,| ,||\ | /_,|_)  
    // '\_/ |/\||'\|'\_'| \  
    //  '   '  `'  `   `'  `                   
                                  
    function mintTo(uint256 _amount, address _user) external onlyOwner {
        require(totalSupply() + _amount <= MAX_SUPPLY, "Not enough mints left");
        _safeMint(_user, _amount);
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURIString = _contractURI;
    }

    function setMaxPerAddress(uint256 _maxPerAddress) external onlyOwner {
        maxPerAddress = _maxPerAddress;
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool succ,) = payable(msg.sender).call{
            value: balance
        }("");
        require(succ, "transfer failed");
    }

    function setIsPublicSaleActive(bool _isPublicSaleActive) external onlyOwner{
        isPublicSaleActive = _isPublicSaleActive;
    }

    //  ,_,  ,  __  ,  ___,  _, 
    //  |_)  | '|_) | ' |   /   
    // '|'\__| _|_)'|___|_,'\_  
    //  '    `'       '       ` 
                    
    function contractURI() public view returns (string memory) {
        return contractURIString;
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }                                

    function mint(uint256 _amount) external payable publicSaleActive mintCompliance(_amount) {

        require(_numberMinted(msg.sender) + _amount <= maxPerAddress, "Max mint limit");

        uint256 price = mintPrice;
        checkValue(price * _amount);
        _safeMint(msg.sender, _amount); 
    }

}