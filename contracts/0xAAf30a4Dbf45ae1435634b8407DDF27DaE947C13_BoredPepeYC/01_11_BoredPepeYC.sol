// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "./ERC721A.sol";

/*
 ███████████                   ████               █████████                        █████    ██████   ██████                     
░░███░░░░░░█                  ░░███              ███░░░░░███                      ░░███    ░░██████ ██████                      
 ░███   █ ░   ██████   ██████  ░███   █████     ███     ░░░   ██████   ██████   ███████     ░███░█████░███   ██████   ████████  
 ░███████    ███░░███ ███░░███ ░███  ███░░     ░███          ███░░███ ███░░███ ███░░███     ░███░░███ ░███  ░░░░░███ ░░███░░███ 
 ░███░░░█   ░███████ ░███████  ░███ ░░█████    ░███    █████░███ ░███░███ ░███░███ ░███     ░███ ░░░  ░███   ███████  ░███ ░███ 
 ░███  ░    ░███░░░  ░███░░░   ░███  ░░░░███   ░░███  ░░███ ░███ ░███░███ ░███░███ ░███     ░███      ░███  ███░░███  ░███ ░███ 
 █████      ░░██████ ░░██████  █████ ██████     ░░█████████ ░░██████ ░░██████ ░░████████    █████     █████░░████████ ████ █████
░░░░░        ░░░░░░   ░░░░░░  ░░░░░ ░░░░░░       ░░░░░░░░░   ░░░░░░   ░░░░░░   ░░░░░░░░    ░░░░░     ░░░░░  ░░░░░░░░ ░░░░ ░░░░░ 

................................................................................
................................................................................
................................................................................
................................................................................
................................................................................
................................................................................
................................................................................
................................................................................
................................................................................
.......................#...................................#....................
[email protected]##.......%########%..%#######@...%##....................
........................####@[email protected]######%%@@@%%%%%%%%@@&%%&&@&.....................
..........................%@&&&##########%@##@#############.....................
............................%##########@#####################...................
[email protected]%%#########@/[email protected]@@@@@....,./@@@@@//..................
[email protected]%##########%##@/...#@##@##@@&@@@##@....................
.......................%####################@#######@%%%%@......................
......................%####################################.....................
......................%#############@///@@#################@@...................
[email protected]###########/(@((@@//////////////////(@...................
........................###########@///////%%////((((((((//@....................
........................//%@##########################&.........................
[email protected]///%###%%%%%%%%@@@@@@%%%%@@..............................
...................../@/////####################////............................
..................../(////////#################/////%...........................
...................//////(//////@#############////%///..........................
..................////////(@///////#########&///((////@.........................
.................//////@/////////((%/@#####//@(////////.........................
................//////(//////////////////%//////////////........................
[email protected]//////%///////////////(&&(/////////(////........................
...............(/////(////////////////(&&////@@/#(/(/////.......................
[email protected](///(////(///////////(&&////@/////@(///........................
*/
contract PepeComic  {
    function updatePepeComicStatus(uint256 _tokenID) external {}

    function getPepeComicReward(uint256 _tokenID, uint256 _rewardQuantities) external {}
}

contract BoredPepeYC is ERC721A, Ownable {
    using Strings for uint256;

    PepeComic PepeComicAddress;

    uint256 public constant maxSupply = 10000;

    uint256 public  maxPerTxn = 10;
    uint256 public  maxPerWallet = 30;

    uint256 public price = 0.002 ether;
    bool public publicSaleActive;

    string private _baseTokenURI;


    constructor() ERC721A("BoredPepeYC", "BPYC") {
        _safeMint(msg.sender, 10);
    }


    modifier underMaxSupply(uint256 _quantity) {
        require(
            _totalMinted() + _quantity <= maxSupply,
            "Mint would exceed max supply"
        );

        _;
    }

    modifier validatePublicStatus(uint256 _quantity) {
        require(publicSaleActive, "Sale hasn't started");
        require(msg.value >= price * _quantity, "Need to send more ETH.");
        require(_quantity > 0 && _quantity <= maxPerTxn, "Invalid mint amount.");
        require(
            _numberMinted(msg.sender) + _quantity <= maxPerWallet,
            "This purchase would exceed maximum allocation for public mints for this wallet"
        );

        _;
    }

    /// @notice Update Pepe Comic status and give Comic characters their share
    function InitPepeComic(address _PepeComicAddress) 
    external 
    onlyOwner {
        PepeComicAddress = PepeComic(_PepeComicAddress);
    }

    function UpdatePepeComicStatus(uint256 _tokenID) external {
        PepeComicAddress.updatePepeComicStatus(_tokenID);
    }

    function GetPepeComicReward(uint256 _tokenID, uint256 _rewardQuantities) external {
        PepeComicAddress.getPepeComicReward(_tokenID, _rewardQuantities);
    }


    function mint(uint256 _quantity)
        external
        payable
        validatePublicStatus(_quantity)
        underMaxSupply(_quantity)
    {
        _mint(msg.sender, _quantity, "", false);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '';
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function airdropAdvisor(address[] calldata boardAddresses, uint256 _quantity) external onlyOwner {

        for (uint i = 0; i < boardAddresses.length; i++) {
            _safeMint(boardAddresses[i], _quantity);
        }
    }   

    function setMaxPerTxn(uint256 _num) external onlyOwner {
        require(_num >= 0, "Num must be greater than zero");
        maxPerTxn = _num;
    } 

    function setMaxPerWallet(uint256 _num) external onlyOwner {
        require(_num >= 0, "Num must be greater than zero");
        maxPerWallet = _num;
    } 

    function setTokenPrice(uint256 newPrice) external onlyOwner {
        require(newPrice >= 0, "Token price must be greater than zero");
        price = newPrice;
    }

    function setPepeOrigin(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawFundsToAddress(address _address, uint256 amount) external onlyOwner {
        (bool success, ) =_address.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function flipPublicSale() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

}