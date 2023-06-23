// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";

/**
 * @title Hatters
 */
contract Hatters is ERC721Tradable {
    
    using SafeMath for uint256;
    
    uint256 public constant MAX_HATTERS = 11111;
    uint256 public daoReserve = 1111; // Reserved tokens that can only be minted by the DAO
    uint256 public price = 0.0666 ether;
    address teamWallet;
    address daoWallet = 0x15f4d11dD90382F7FD81D0ca37D5D7e44706ffCE;
    address genesisWallet;
    address public hatContract = 0x23c9e48F7E9fCa487bd0c4f41EE1445812d871fd;
    bool public locked = true;
    bool public frozen = false;
    string public baseUri;

    constructor(address payable _teamWallet, address payable _genesisWallet, string memory _baseUri, address _proxyRegistryAddress)
        ERC721Tradable("THEM Hatters", "HATTER", _proxyRegistryAddress)
    {
        teamWallet = _teamWallet;
        genesisWallet = _genesisWallet;
        baseUri = _baseUri;
    }

    modifier onlyDAO {
        require(msg.sender == daoWallet, 'Only the DAO can do this.');
        _;
    }

    /**
     * Buy a token and mint it in the process.
     */
    function buyOne() external payable {
        uint256 supply = totalSupply();
        require(!frozen, 'Minting hatters has been frozen by the DAO.');
        require(!locked, 'Buying hatters is not unlocked yet. SoonTM');
        require(supply < MAX_HATTERS - daoReserve, 'Sold out.');
        require(price <= msg.value, 'Price must be equal to or larger than the sales price');

        _safeMint(msg.sender, supply + 1);
        
        uint256 _splitDAO = msg.value * 50 / 100;
        uint256 _splitTeam = msg.value * 40 / 100;
        uint256 _splitGenesis = msg.value - _splitDAO - _splitTeam;
        payable(daoWallet).transfer(_splitDAO);
        payable(teamWallet).transfer(_splitTeam);
        payable(genesisWallet).transfer(_splitGenesis);
    }

    /**
     * Buy tokens and mint them in the process.
     * @param _amount amount of the tokens to be minted
     */
    function buyMany(uint256 _amount) external payable {
        uint256 supply = totalSupply();
        require(!frozen, 'Minting hatters has been frozen by the DAO.');
        require(!locked, 'Buying hatters is not unlocked yet. SoonTM');
        require(_amount < 21, 'You cannot mint more than 20 Tokens at once.');
        require(supply < MAX_HATTERS - daoReserve, 'Sold out.');
        require(supply + _amount <= MAX_HATTERS - daoReserve, 'Not enough Tokens left to mint.');
        require(_amount * price <= msg.value, 'Not enough ETH sent.');

        for (uint256 i = 1; i <= _amount; i++) {
            _safeMint(msg.sender, supply + i);
        }

        uint256 _splitDAO = msg.value * 50 / 100;
        uint256 _splitTeam = msg.value * 40 / 100;
        uint256 _splitGenesis = msg.value - _splitDAO - _splitTeam;
        payable(daoWallet).transfer(_splitDAO);
        payable(teamWallet).transfer(_splitTeam);
        payable(genesisWallet).transfer(_splitGenesis);
    }

    /**
     * Iterate through HAT holders and airdrop one hatter to each.
     */
    function airdropToHatHolders(uint256 offset, uint256 size) public onlyOwner {
        require(!frozen, 'Minting hatters has been frozen by the DAO.');
        for (uint256 i = 0; i < size; i++) {
            address holder = IERC721(hatContract).ownerOf(offset+i);
            if (holder != 0x000000000000000000000000000000000000dEaD) {
                mintTo(holder);
            }
        }
    }

    /**
     * DAO can change price in case ETH does crazy things.
     */
    function changePrice(uint256 _price) public onlyDAO {
        price = _price;
    }

    /**
     * DAO can freeze the minting permanently. Reserve is excluded from this.
     */
    function freezeMinting() public onlyDAO {
        frozen = true;
    }

    /**
     * DAO can change the dao wallet.
     */
    function changeDaoWallet(address _daoWallet) public onlyDAO {
        daoWallet = _daoWallet;
    }
    
    /**
     * Owner can change team wallet.
     */
    function changeTeamWallet(address _teamWallet) public onlyOwner {
        teamWallet = _teamWallet;
    }

    /**
     * Owner can change the genesis wallet.
     */
    function changeGenesisWallet(address _genesisWallet) public onlyOwner {
        genesisWallet = _genesisWallet;
    }

    /**
     * Update Base Uri.
     */
    function changeBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    /**
     * Set address of the hat contract for the airdrop
     */
    function setHatContract(address _hatContract) public onlyOwner {
        hatContract = _hatContract;
    }

    /**
     * Irreversably unlock buying.
     */
    function unlock() public onlyOwner {
        require(locked, 'Contract is already unlocked');
        locked = false;
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * @dev Mints a token to an address
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to) public onlyOwner {
        uint256 supply = totalSupply();
        require(!frozen, 'Minting hatters has been frozen forever by the DAO.');
        require(supply < MAX_HATTERS - daoReserve, 'Sold out!');
        _mint(_to, supply + 1);
    }

    /**
     * @dev Mints tokens to an address
     * @param _to address of the future owner of the token
     * @param _amount amount of the tokens to be minted
     */
    function mintManyTo(address _to, uint256 _amount) public onlyOwner {
        uint256 supply = totalSupply();
        require(!frozen, 'Minting hatters has been frozen forever by the DAO.');
        require(_amount < 21, 'You cannot mint more than 20 Tokens at once.');
        require(supply + _amount <= MAX_HATTERS - daoReserve, 'Not enough Tokens left to mint.');

        for (uint256 i = 1; i <= _amount; i++) {
            _mint(_to, supply + i);
        }
    }

    /**
     * @dev DAO can mint the reserve tokens.
     * @param _amount amount of the tokens to be minted
     */
    function daoMintReserve(uint256 _amount) public onlyDAO {
        uint256 supply = totalSupply();
        require(_amount <= daoReserve, 'Not enough Tokens left to mint.');

        for (uint256 i = 1; i <= _amount; i++) {
            _mint(daoWallet, supply + i);
        }
    
        daoReserve = daoReserve - _amount;
    }


    function baseTokenURI() override public view returns (string memory) {
        return baseUri;
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), "contract"));
    }
}