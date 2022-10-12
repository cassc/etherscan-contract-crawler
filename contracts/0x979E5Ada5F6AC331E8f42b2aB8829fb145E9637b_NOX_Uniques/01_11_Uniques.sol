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

contract NOX_Uniques is ERC1155DUpgradeable, IERC2981Upgradeable {
    
    address public admin;

    uint256 public id;

    string public contractURI;

    /**
     * @notice Constructor of the contract.
     * @param _metadata Metadata of the contract.
     * @param _contractURI Contract Uri.
     */
    function initialize(string memory _metadata, string memory _contractURI) virtual public initializer {
        admin = msg.sender;
        id = 1;
        contractURI = _contractURI;
        __ERC1155_init(_metadata);
        for (uint256 i = 0; i < 14; i++) {
            unchecked {id++;}
            _mint(msg.sender, (id - 1), 1, "");
        }  
    }

    /**
     * @notice Function to check the implemented interafaces of the contract.
     * @param interfaceId  Interface identifier.
     * @return True if the interface is implemented, false otherwise.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC1155DUpgradeable, IERC165Upgradeable) returns (bool) {
        return (
        ERC1155DUpgradeable.supportsInterface(interfaceId) 
        || interfaceId == type(IERC2981Upgradeable).interfaceId);
    }

    /**
     * @notice Function to check the royalties of the contract.
     * @param tokenId  Token identifier.
     * @param _salePrice Sale price of the token.
     * @return _receiver Receiver of the royalties.
     * @return _royaltyAmount Amount of the royalties to receive.
     */
    function royaltyInfo(uint256 tokenId, uint256 _salePrice) virtual override external view returns (address _receiver, uint256 _royaltyAmount) {
        require(tokenId < id, "Error: invalid token id");
        return (0xF7d320Fce853F3F816Cb39bed66a7fb8Ea46cf0e, _salePrice * 5 / 100);
    }

    /**
     * @notice Function to set the admin of the contract.
     * @param _admin Address of the new admin.
     */
    function setAdmin(address _admin) virtual public onlyAdmin {
        require(admin != _admin, "Error: admin already setted");
        admin = _admin;
    }

    /**
     * @notice Setter to change the URI.
     * @param _newURI The new uri.
     */
    function setURI(string memory _newURI) virtual public onlyAdmin {
        require(keccak256(abi.encodePacked(contractURI)) != keccak256(abi.encodePacked(_newURI)), "Error: uri already setted");
        _setURI(_newURI);
        emit URI(_newURI, id);
    }

    /**
     * @notice Setter to change the ContractURI.
     * @param _newURI The new contractURI.
     */
    function setContractUri(string memory _newURI) virtual public onlyAdmin {
        require(keccak256(abi.encodePacked(contractURI)) != keccak256(abi.encodePacked(_newURI)), "Error: contractURI already setted");
        contractURI = _newURI;
    }

    /**
     * @notice Function to see the address of the admin.
     * @return admin Address of the admin.
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
     * @param _recipient Address to withdraw.
     * @param _amount Amount to withdraw.
     */
    function withdrawFunds(address payable _recipient, uint256 _amount) virtual public onlyAdmin {
        AddressUpgradeable.sendValue(_recipient, _amount);
    }

    /**
     * @dev only the admin is allowed to call the functions that implement this modifier
     */
    modifier onlyAdmin {
        require(msg.sender == admin, "Error: only admin can call this function");
        _;
    }

}