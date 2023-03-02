//SPDX-License-Identifier: GPL-3.0

//''''''''''''''''''''''''''''''''''''''',;cxKWMMMMMMMMWKdc;,''''''''''''''''''''''''''''''''''''''',dNMWO:'''''''';lONWWKxlccccccccccldKWWNOl;'''''''';
//'''''''''''''''''''''''''''''''''''''''''',cxXWMMMMMXx:,'''''''''''''''''''''''''''''''''''''''''',dNMMNOl,'''''''';lx0XKko:,'''',:okKX0xl;'''''''',lk
//'''''''''''''''''''''''''''''''''''''''''''',lKMMMMXo,'''''''''''''''''''''''''''''''''''''''''''''dNMMMMN0o;''''''''',cdOXXOdccdOXXOdc,''''''''';o0NM
//''''''''';:cccccccccccccccccccccc:;'''''''''',xNMMWO;'''''''''',::ccccccccccccccccccccccc:,''''''',dNMMMMMMWKd:'''''''''',:dOKXNWXxc,'''''''''':dKWMMM
//'''''''',dXNNNNNNNNNNNNNNNNNNNNNNXKx:'''''''''oNMMWk;'''''''';o0XNNNNNNNNNNNNNNNNNNNNNNNNKl''''''',dNMMMMMMMMWXxc,'''''''''',:okKX0xl;'''''''cxKWMMMMM
//'''''''',xWMMMMMMMMMMMMMMMMMMMMMMMMW0:''''''''oNMMWk;''''''''oNMMMMMMMMMMMMMMMMMMMMMMMMMMNo''''''',dNMMMMMMMMMMWNkl,'''''''''''';lx0XKkxdolokXWMMMMMMM
//'''''''',xWMMMMMMMMMMMMMMMMMMMMMMMMMXl''''''''oNMMWk;''''''',dWMMMMMMMMMMMMMMMMMMMMMMMMMMNo''''''',dNMMMMMMMMMMMMMNOo;'''''''''''''c0WMMMWWWMMMMMMMMMM
//'''''''',xWMMMMMMMMMMMMMMMMMMMMMMMMMNo''''''''oNMMWk;''''''',dWMMMMMMMMMMMMMMMMMMMMMMMMMMNo''''''',dNMMMMMMMMMMMMMMMW0o,'''''''''',dNMMMMMMMMMMMMMMMMM
//'''''''',xWMMMMMMMMMMMMMMMMMMMMMMMMMNo''''''''oNMMWk;''''''',dWMMMMMMMMMMMMMMMMMMMMMMMMMMNo''''''',dNMMMMMMMMMMMMMMMW0o,'''''''''',dNMMMMMMMMMMMMMMMMM
//'''''''',xWMMMMMMMMMMMMMMMMMMMMMMMMMNo''''''''oNMMWk;''''''',dWMMMMMMMMMMMMMMMMMMMMMMMMMMNo''''''',dNMMMMMMMMMMMMMNOo;'''''''''''''c0WMMMWWWMMMMMMMMMM
//'''''''',xWMMMMMMMMMMMMMMMMMMMMMMMMMNo''''''''oNMMWk;''''''',dWMMMMMMMMMMMMMMMMMMMMMMMMMMKc''''''',dNMMMMMMMMMMWXkl,'''''''''''';lx0XKkddoclkXWMMMMMMM
//'''''''',xWMMMMMMMMMMMMMMMMMMMMMMMMMNo''''''''oNMMWk;''''''''dXNNNNNNNNNNNNNNNNNNNNWNNNKOl,''''''',dNMMMMMMMMWXxc,'''''''''',:okKX0xl;'''''',:xKWMMMMM
//'''''''',xWMMMMMMMMMMMMMMMMMMMMMMMMMNo''''''''oNMMWk;'''''''';cccccccccccccccccccccccc:;,''''''''',dNMMMMMMWKd:'''''''''',:dOXXNWXxc,'''''''''':d0NMMM
//'''''''',xWMMMMMMMMMMMMMMMMMMMMMMMMMNo''''''''oNMMWk;''''''''''''''''''''''''''''''''''''''''''''';OWMMMMN0o;''''''''',cd0XKOdccoOKX0dc;''''''''';oONW
//'''''''',xWMMMMMMMMMMMMMMMMMMMMMMMMMNo''''''''oNMMWk;''''''''''''''''''''''''''''''''''''''''''',lONMMMNOl,'''''''';lx0XKko:,'''',:okKX0xl;'''''''',lk
//,''''''',kWMMMMMMMMMMMMMMMMMMMMMMMMMNo,'''''',dNMMWk;'''''''''''''''''''''''''''''''''''''''',:lkXWMMMWO:''''''',;oONWWKxlcccccccccclxKWMNOo;'''''''';

// ██████   ██████  ██     ██ ███████ ██████  ███████ ██████      ██████  ██    ██                       
// ██   ██ ██    ██ ██     ██ ██      ██   ██ ██      ██   ██     ██   ██  ██  ██                        
// ██████  ██    ██ ██  █  ██ █████   ██████  █████   ██   ██     ██████    ████                         
// ██      ██    ██ ██ ███ ██ ██      ██   ██ ██      ██   ██     ██   ██    ██                          
// ██       ██████   ███ ███  ███████ ██   ██ ███████ ██████      ██████     ██                          
                                                                                                  
// ██    ██ ███    ██ ██ ██    ██ ███████ ██████  ███████ ███████ ██      ██      ███████    ██  ██████  
// ██    ██ ████   ██ ██ ██    ██ ██      ██   ██ ██      ██      ██      ██      ██         ██ ██    ██ 
// ██    ██ ██ ██  ██ ██ ██    ██ █████   ██████  ███████ █████   ██      ██      █████      ██ ██    ██ 
// ██    ██ ██  ██ ██ ██  ██  ██  ██      ██   ██      ██ ██      ██      ██      ██         ██ ██    ██ 
//  ██████  ██   ████ ██   ████   ███████ ██   ██ ███████ ███████ ███████ ███████ ███████ ██ ██  ██████  


pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "./ERC1155DUpgradeable.sol";

contract NOX_SerialsV2 is ERC1155DUpgradeable, IERC2981Upgradeable {

    bytes32 public ATmerkleSeed;

    bytes32 public MLmerkleSeed;
    
    uint256 public AT_id;

    uint256 public ML_id;

    bool public paused;

    bool public whitelistPaused;

    address public admin;

    string public contractURI;

    mapping(address => uint256) public AT_WLClaimed;

    mapping(address => uint256) public ML_WLClaimed;

    uint256 public price;

    address public crossmint;

    /**
     * @dev only the admin is allowed to call the functions that implement this modifier
     */
    modifier onlyAdmin {
        require(msg.sender == admin, "Error: only admin can call this function");
        _;
    }

    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Function to receive funds.
     */
    receive() external payable {}

    /**
     * @notice Function to set up new module of the contract.
     */
    function initializeV2() external reinitializer(2) {
        price = 0.057 ether;
        crossmint = 0xdAb1a1854214684acE522439684a145E62505233;
    }

    /** 
     * @notice Function to mint tokens with FIAT.
     * @param _to Address of the receiver.
     * @param _amount Amount of tokens to mint.
     * @param _type Type of token to mint.
     */
    function crossMint(address _to, uint256 _amount, uint8 _type) external payable {
        require(msg.sender == crossmint, "Error: not crossmint");
        require(_type == 1 || _type == 2, "Error: invalid type");
        require(_amount > 0, "Error: you can't mint less than one");
        require(msg.value >= price * _amount, "Error: insufficient funds");
        if (_type == 1) {
            require((AT_id + _amount) <= 7001, "Error: max supply reached or will be reached");
            for (uint256 i = 0; i < _amount; i++) {
                unchecked {AT_id++;}
                _mint(_to, (AT_id - 1), 1, "");
            }
        } else {
            require((ML_id + _amount) <= (MAX_SUPPLY + 1), "Error: max supply reached or will be reached");
            for (uint256 i = 0; i < _amount; i++) {
                unchecked {ML_id++;}
                _mint(_to, (ML_id - 1), 1, "");
            }
        }
    }

    /**
     * @notice Function to mint AT tokens in the public sale.
     * @param _amount Amount of tokens to mint.
     */
    function mintPublicAT10(uint256 _amount) external payable {
        require(paused == false, "Error: public mint is paused");
        require(_amount > 0, "Error: you can't mint less than one");  
        require((AT_id + _amount) <= 7001, "Error: max supply reached or will be reached");
        require(msg.value >= price * _amount, "Error: insufficient funds");
        for (uint256 i = 0; i < _amount; i++) {
            unchecked {AT_id++;}
            _mint(msg.sender, (AT_id - 1), 1, "");
        }
    }

    /**
     * @notice Function to mint ML tokens in the public sale.
     * @param _amount Amount of tokens to mint.
     */
    function mintPublicML10(uint256 _amount) external payable {
        require(paused == false, "Error: public mint is paused");
        require(_amount > 0, "Error: you can't mint less than one");  
        require((ML_id + _amount) <= (MAX_SUPPLY + 1), "Error: max supply reached or will be reached");
        require(msg.value >= price * _amount, "Error: insufficient funds");
        for (uint256 i = 0; i < _amount; i++) {
            unchecked {ML_id++;}
            _mint(msg.sender, (ML_id - 1), 1, "");
        }
    }

    /**
     * @notice Set a new contract admin.
     * @param _admin The address of the new contract admin.
     */
    function setAdmin(address _admin) external onlyAdmin {
        require(admin != _admin, "Error: admin already setted");
        admin = _admin;
    }

    /**
     * @notice Setter to pause or unpause the public mint.
     * @param _paused True or false, depends on the new desired state.
     */
    function setPaused(bool _paused) external onlyAdmin {
        require(paused != _paused, "Error: public mint already paused");
        paused = _paused;
    }

    /**
     * @notice Setter to change the URI.
     * @param _newURI The new URI.
     */
    function setURI(string memory _newURI) external onlyAdmin {
        require(keccak256(abi.encodePacked(contractURI)) != keccak256(abi.encodePacked(_newURI)), "Error: uri already setted");
        _setURI(_newURI);
        emit URI(_newURI, MAX_SUPPLY);
    }

    /**
     * @notice Setter to change the ContractURI.
     * @param _newURI The new ContractURI.
     */
    function setContractUri(string memory _newURI) external onlyAdmin {
        require(keccak256(abi.encodePacked(contractURI)) != keccak256(abi.encodePacked(_newURI)), "Error: uri already setted");
        contractURI = _newURI;
    }

    /**
     * @notice Setter to change the price.
     * @param _newPrice The new price.
     */
    function setPrice(uint256 _newPrice) external onlyAdmin {
        require(price != _newPrice, "Error: price already setted");
        price = _newPrice;
    }

    /**
     * @notice Setter to change the crossmint address.
     * @param _crossmint The new crossmint address.
     */
    function setCrossmint(address _crossmint) external onlyAdmin {
        require(crossmint != _crossmint, "Error: crossmint already setted");
        crossmint = _crossmint;
    }

    /**
     * @notice Function to withdraw the funds of the contract.
     * @param recipient Address to withdraw.
     * @param amount Amount to withdraw.
     */
    function withdrawFunds(address payable recipient, uint256 amount) external onlyAdmin {
        AddressUpgradeable.sendValue(recipient, amount);
    }

    /**
     * @notice Function to check the royalties of the contract.
     * @param tokenId Token identifier.
     * @param _salePrice Sale price of the token.
     * @return _receiver Receiver of the royalties.
     * @return _royaltyAmount Amount of the royalties to receive.
     */
    function royaltyInfo(uint256 tokenId, uint256 _salePrice) external view virtual override returns(address _receiver, uint256 _royaltyAmount) {
        require(tokenId > 0 && tokenId <= MAX_SUPPLY, "Error: invalid token id");
        return (0xF7d320Fce853F3F816Cb39bed66a7fb8Ea46cf0e, (_salePrice * 5) / 100);
    }

    /**
     * @notice Function to check the implemented interafaces of the contract.
     * @param interfaceId Interface identifier.
     * @return True if the interface is implemented, false otherwise.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC1155DUpgradeable, IERC165Upgradeable) returns(bool) {
        return (
        ERC1155DUpgradeable.supportsInterface(interfaceId) 
        || interfaceId == type(IERC2981Upgradeable).interfaceId);
    }

    /**
     * @notice Getter of the contract admin address.
     * @dev neccessary to set things on opensea.
     * @return The contract admin address.
     */
    function owner() public view returns (address) {
        return admin;
    }

}