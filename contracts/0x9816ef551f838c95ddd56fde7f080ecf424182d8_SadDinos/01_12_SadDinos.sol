pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//    _____           _   _____  _
//   / ____|         | | |  __ \(_)
//  | (___   __ _  __| | | |  | |_ _ __   ___  ___
//   \___ \ / _` |/ _` | | |  | | | '_ \ / _ \/ __|
//   ____) | (_| | (_| | | |__| | | | | | (_) \__ \
//  |_____/ \__,_|\__,_| |_____/|_|_| |_|\___/|___/

contract SadDinos is ERC721A, Ownable {
    uint256 public constant MAX_SUPPLY = 4500;

    bool public isPublicSaleActive = false;
    uint256 public freeMax = 1;
    uint256 public maxPerAddress = 15;
    uint256 public maxPerTx = 15;
    uint256 public mintPrice = 0.005 ether;

    string public contractURIString = "https://api.saddinos.xyz/contract";
    string public baseURI = "https://api.saddinos.xyz/metadata/";

    mapping(address => uint256) private _freeMinted;

    constructor() ERC721A("SadDinos", "SD") {}

    //  _____       _     _ _       __      ___
    //  |  __ \     | |   | (_)      \ \    / (_)
    //  | |__) |   _| |__ | |_  ___   \ \  / / _  _____      __
    //  |  ___/ | | | '_ \| | |/ __|   \ \/ / | |/ _ \ \ /\ / /
    //  | |   | |_| | |_) | | | (__     \  /  | |  __/\ V  V /
    //  |_|    \__,_|_.__/|_|_|\___|     \/   |_|\___| \_/\_/

    function contractURI() public view returns (string memory) {
        return contractURIString;
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function numberFreeMinted(address _owner) public view returns (uint256) {
        return _freeMinted[_owner];
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

    //   ______      _                        _ 
    //  |  ____|    | |                      | |
    //  | |__  __  _| |_ ___ _ __ _ __   __ _| |
    //  |  __| \ \/ / __/ _ \ '__| '_ \ / _` | |
    //  | |____ >  <| ||  __/ |  | | | | (_| | |
    //  |______/_/\_\\__\___|_|  |_| |_|\__,_|_|
                                            

    function mint(uint256 _amount) external payable publicSaleActive mintCompliance(_amount) {

        uint256 userMintsTotal = _numberMinted(msg.sender);
        require(userMintsTotal + _amount <= maxPerAddress, "Max mint limit");

        uint256 payFor = _amount;
        uint256 freeMints =  _freeMinted[msg.sender];
        if(freeMints < freeMax){
            uint256 freeAllowed = freeMax - freeMints;
            if( freeAllowed  > _amount){
                payFor = 0;
            } else {
                payFor = payFor - freeAllowed;
            }
        }

        uint256 price = mintPrice;
        checkValue(price * payFor);

        _freeMinted[msg.sender] += (_amount - payFor);
        _safeMint(msg.sender, _amount); 
    }


    //   _____      _            _       
    //  |  __ \    (_)          | |      
    //  | |__) | __ ___   ____ _| |_ ___ 
    //  |  ___/ '__| \ \ / / _` | __/ _ \
    //  | |   | |  | |\ V / (_| | ||  __/
    //  |_|   |_|  |_| \_/ \__,_|\__\___|
                                    
                                  
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

    //    ____                           
    //   / __ \                          
    //  | |  | |_      ___ __   ___ _ __ 
    //  | |  | \ \ /\ / / '_ \ / _ \ '__|
    //  | |__| |\ V  V /| | | |  __/ |   
    //   \____/  \_/\_/ |_| |_|\___|_|   
                                    
                                  
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

    function setFreeMintMax(uint256 _freeMintMax) external onlyOwner {
        freeMax = _freeMintMax;
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

    //   __  __           _ _  __ _           
    //  |  \/  |         | (_)/ _(_)          
    //  | \  / | ___   __| |_| |_ _  ___ _ __ 
    //  | |\/| |/ _ \ / _` | |  _| |/ _ \ '__|
    //  | |  | | (_) | (_| | | | | |  __/ |   
    //  |_|  |_|\___/ \__,_|_|_| |_|\___|_|   
                                        
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

    //   _____       _                        _
    //  |_   _|     | |                      | |
    //    | |  _ __ | |_ ___ _ __ _ __   __ _| |
    //    | | | '_ \| __/ _ \ '__| '_ \ / _` | |
    //   _| |_| | | | ||  __/ |  | | | | (_| | |
    //  |_____|_| |_|\__\___|_|  |_| |_|\__,_|_|

    // Override start token id to set to 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}