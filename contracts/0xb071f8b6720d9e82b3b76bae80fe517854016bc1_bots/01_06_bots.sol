//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

//import "./dependencies/ERC721A.sol";
import './dependencies/Payout.sol';
import './dependencies/ERC721A.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract bots is ERC721A, Ownable {

    uint public maxSupply = 100;
    uint public price = 0.1337 ether;

    address payable payout;
    address proxyRegistryAddress;
    constructor() ERC721A("BOTSNFT", "BOTS") 
    {
        proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
        Payout payout_ = new Payout();
        payout = payable(address(payout_));        
    }

    function mint() external payable {
        require(msg.value / price > 0, "Zero-mint");
        uint256 quantity = msg.value / price;
        require(
            _totalMinted() + quantity <= maxSupply,
            "Not enough supply"
        );
        _mint(msg.sender, quantity);
        (bool success, ) = payout.call{value: msg.value}("");
        require(success, "Payout failed");
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) return true;

        return super.isApprovedForAll(_owner, _operator);
    }

    function setProxyRegistry(address proxyRegistryAddress_)
        external
        onlyOwner
    {
        proxyRegistryAddress = proxyRegistryAddress_;
    }

    function _baseURI() internal pure override returns (string memory) {
        return 'https://botsnft.art/json/';
    }    
    
    function contractURI() pure external returns(string memory) {
        return string(abi.encodePacked(_baseURI(), 'opensea.json'));
    }  

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}