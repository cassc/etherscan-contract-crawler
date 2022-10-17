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

import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "./ERC1155DUpgradeable.sol";

contract NOX_Serials is ERC1155DUpgradeable, IERC2981Upgradeable {

    bytes32 public ATmerkleSeed;

    bytes32 public MLmerkleSeed;
    
    uint256 public AT_id;

    uint256 public ML_id;

    uint256 public constant whitelistPrice = 0.69 ether;

    uint256 public constant publicPrice = 0.69 ether;

    bool public paused;

    bool public whitelistPaused;

    address public admin;

    string public contractURI;

    mapping(address => uint256) public AT_WLClaimed;

    mapping(address => uint256) public ML_WLClaimed;

    /**
     * @notice Constructor of the contract.
     * @param _metadata Metadata of the NFT.
     * @param _ATseed Merkle seed containing the AT whitelist
     * @param _MLseed Merkle seed containing the ML whitelist
     * @param _contractURI Contract Uri.
     */
    function initialize(string memory _metadata, bytes32 _ATseed, bytes32 _MLseed, string memory _contractURI) virtual public initializer {
        admin = msg.sender;
        AT_id = 1;
        ML_id = 7001;
        paused = true;
        whitelistPaused = true;
        contractURI = _contractURI;
        ATmerkleSeed = _ATseed;
        MLmerkleSeed = _MLseed;
        __ERC1155_init(_metadata);
        for (uint256 i = 0; i < 60; i++) {
            unchecked{AT_id++;}
            _mint(msg.sender, (AT_id - 1), 1, "");
        }
        for (uint256 i = 0; i < 60; i++) {
            unchecked{ML_id++;}
            _mint(msg.sender, (ML_id - 1), 1, "");
        }
    }

    /**
     * @notice Function to check the implemented interafaces of the contract.
     * @param interfaceId Interface identifier.
     * @return True if the interface is implemented, false otherwise.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC1155DUpgradeable, IERC165Upgradeable) returns (bool) {
        return (
        ERC1155DUpgradeable.supportsInterface(interfaceId) 
        || interfaceId == type(IERC2981Upgradeable).interfaceId);
    }

    /**
     * @notice Function to check the royalties of the contract.
     * @param tokenId Token identifier.
     * @param _salePrice Sale price of the token.
     * @return _receiver Receiver of the royalties.
     * @return _royaltyAmount Amount of the royalties to receive.
     */
    function royaltyInfo(uint256 tokenId, uint256 _salePrice) virtual override external view returns (address _receiver, uint256 _royaltyAmount) {
        require(tokenId > 0 && tokenId <= MAX_SUPPLY, "Error: invalid token id");
        return (0xF7d320Fce853F3F816Cb39bed66a7fb8Ea46cf0e, _salePrice * 5 / 100);
    }

    /**
     * @notice Function to mint AT tokens in the public sale.
     * @param _amount Amount of tokens to mint.
     */
    function mintPublicAT10(uint256 _amount) public payable {
        require(paused == false, "Error: public mint is paused");
        require(_amount > 0, "Error: you can't mint less than one");  
        require((AT_id + _amount) <= 7001, "Error: max supply reached or will be reached");
        require(msg.value >= publicPrice * _amount, "Error: insufficient funds");
        for (uint256 i = 0; i < _amount; i++) {
            unchecked {AT_id++;}
            _mint(msg.sender, (AT_id - 1), 1, "");
        }
    }

    /**
     * @notice Function to mint ML tokens in the public sale.
     * @param _amount Amount of tokens to mint.
     */
    function mintPublicML10(uint256 _amount) public payable {
        require(paused == false, "Error: public mint is paused");
        require(_amount > 0, "Error: you can't mint less than one");  
        require((ML_id + _amount) <= (MAX_SUPPLY + 1), "Error: max supply reached or will be reached");
        require(msg.value >= publicPrice * _amount, "Error: insufficient funds");
        for (uint256 i = 0; i < _amount; i++) {
            unchecked {ML_id++;}
            _mint(msg.sender, (ML_id - 1), 1, "");
        }
    }

    /**
     * @notice Function to mint AT tokens in the whitelist sale.
     * @param _merkleProof Proof that you are on the whitelist.
     * @param _amount Amount of tokens to mint.
     */
    function mintWhitelistAT10(bytes32[] calldata _merkleProof, uint256 _amount) public payable {
        require(whitelistPaused == false, "Error: whitelist mint is paused");
        require(_amount > 0, "Error: you can't mint less than one");
        require((AT_id + _amount) <= 5001, "Error: max whitelist supply reached or will be reached");
        require(AT_WLClaimed[msg.sender] + _amount <= 5, "Error: you cant own more than 5 NFTs in the whitelist");
        require(msg.value >= whitelistPrice * _amount, "Error: insufficient funds");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProofUpgradeable.verify(_merkleProof, ATmerkleSeed, leaf), "Error: you are not on the whitelist");
        AT_WLClaimed[msg.sender]+= _amount;
        for (uint256 i = 0; i < _amount; i++) {
            unchecked {AT_id++;}
            _mint(msg.sender, (AT_id - 1), 1, "");
        }
    }

    /**
     * @notice Function to mint ML tokens in the whitelist sale.
     * @param _merkleProof Proof that you are on the whitelist.
     * @param _amount Amount of tokens to mint.
     */
    function mintWhitelistML10(bytes32[] calldata _merkleProof, uint256 _amount) public payable {
        require(whitelistPaused == false, "Error: whitelist mint is paused");
        require(_amount > 0, "Error: you can't mint less than one");
        require((ML_id + _amount) <= 9001, "Error: max whitelist supply reached or will be reached");
        require(ML_WLClaimed[msg.sender] + _amount <= 5, "Error: you cant own more than 5 NFTs in the whitelist");
        require(msg.value >= whitelistPrice * _amount, "Error: insufficient funds");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProofUpgradeable.verify(_merkleProof, MLmerkleSeed, leaf), "Error: you are not on the whitelist");
        ML_WLClaimed[msg.sender]+= _amount;
        for (uint256 i = 0; i < _amount; i++) {
            unchecked {ML_id++;}
            _mint(msg.sender, (ML_id - 1), 1, "");
        }
    }

    /**
     * @notice Set a new merkle seed containing a new AT whitelist.
     * @param _seed The new merkle seed containing the new AT whitelist.
     */
    function setATSeed(bytes32 _seed) virtual public onlyAdmin {
        require(ATmerkleSeed != _seed, "Error: seed already setted");
        ATmerkleSeed = _seed;
    }

    /**
     * @notice Set a new merkle seed containing a new ML whitelist.
     * @param _seed The new merkle seed containing the new ML whitelist.
     */
    function setMLSeed(bytes32 _seed) virtual public onlyAdmin {
        require(MLmerkleSeed != _seed, "Error: seed already setted");
        MLmerkleSeed = _seed;
    }

    /**
     * @notice Set a new contract admin.
     * @param _admin The address of the new contract admin.
     */
    function setAdmin(address _admin) virtual public onlyAdmin {
        require(admin != _admin, "Error: admin already setted");
        admin = _admin;
    }

    /**
     * @notice Setter to pause or unpause the whitelist mint.
     * @param _paused True or false, depends on the new desired state.
     */
    function setWhitelistPaused(bool _paused) virtual public onlyAdmin {
        require(whitelistPaused != _paused, "Error: whitelist already paused");
        whitelistPaused = _paused;
    }

    /**
     * @notice Setter to pause or unpause the public mint.
     * @param _paused True or false, depends on the new desired state.
     */
    function setPaused(bool _paused) virtual public onlyAdmin {
        require(paused != _paused, "Error: public mint already paused");
        paused = _paused;
    }

    /**
     * @notice Setter to change the URI.
     * @param _newURI The new URI.
     */
    function setURI(string memory _newURI) virtual public onlyAdmin {
        require(keccak256(abi.encodePacked(contractURI)) != keccak256(abi.encodePacked(_newURI)), "Error: uri already setted");
        _setURI(_newURI);
        emit URI(_newURI, MAX_SUPPLY);
    }

    /**
     * @notice Setter to change the ContractURI.
     * @param _newURI The new ContractURI.
     */
    function setContractUri(string memory _newURI) virtual public onlyAdmin {
        require(keccak256(abi.encodePacked(contractURI)) != keccak256(abi.encodePacked(_newURI)), "Error: uri already setted");
        contractURI = _newURI;
    }

    /**
     * @notice Getter of the contract admin address.
     * @dev neccessary to set things on opensea.
     * @return The contract admin address.
     */
    function owner() virtual public view returns (address) {
        return admin;
    }

    /**
     * @notice Function to receive funds.
     */
    receive() external payable {}

    /**
     * @notice Function to withdraw the funds of the contract.
     * @param recipient Address to withdraw.
     * @param amount Amount to withdraw.
     */
    function withdrawFunds(address payable recipient, uint256 amount) virtual public onlyAdmin {
        AddressUpgradeable.sendValue(recipient, amount);
    }

    /**
     * @dev only the admin is allowed to call the functions that implement this modifier
     */
    modifier onlyAdmin {
        require(msg.sender == admin, "Error: only admin can call this function");
        _;
    }

}