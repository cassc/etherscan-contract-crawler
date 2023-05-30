// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Juicebox Project Cards v1.1
/// @notice Limited testing so far. Use at your own risk. The code is straightforward and very simple. 
/// @author @nnnnicholas
/// @dev Thanks to the jb contract crew for help debugging some issues.

import {IERC1155, ERC1155, IERC165} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IJBDirectory} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol";
import {Config} from "src/Structs/Config.sol";

/*//////////////////////////////////////////////////////////////
                             ERRORS 
//////////////////////////////////////////////////////////////*/

error InsufficientFunds();

/*//////////////////////////////////////////////////////////////
                             CONTRACT 
 //////////////////////////////////////////////////////////////*/

contract JuiceboxProjectCards is ERC1155, Ownable {
    /*//////////////////////////////////////////////////////////////
                             EVENTS 
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when the price of the NFT is set
    event PriceSet(uint256 _price);

    /// @dev Emitted when the address that receives tokens from the Juicebox project that collects revenues is set
    event RevenueRecipientSet(address _revenueRecipient);

    /// @dev Emitted when the address of the JBProjects contract is set
    event MetadataSet(address _JBProjects);

    /// @dev Emitted when the URI of the contract metadata is set
    event ContractUriSet(string _contractUri);

    /// @dev Emitted when funds are withdrawn
    event Withdrew(address _revenueRecipient, uint256 _amount);

    /*//////////////////////////////////////////////////////////////
                           STORAGE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev The address of the JBProjects contract
    IERC721Metadata public projects;

    /// @dev The address that receives tokens from the Juicebox project that collects revenues
    address payable public revenueRecipient;

    /// @dev The price of the NFT in wei
    uint256 public price;

    /// @dev The URI of the contract metadata
    string private contractUri;

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(Config memory _config) ERC1155("") {
        setMetadata(_config.projects); // Set the address of the JBProjects contract as the Metadata resolver
        setRevenueRecipient(_config.revenueRecipient); // Set the address that mint revenues are forwarded to
        setPrice(_config.price); // Set the price of the NFT
        if (bytes(contractUri).length > 0) {
            setContractUri(_config.contractUri); // Set the URI of the contract metadata if it is not empty
        }
    }

    /*//////////////////////////////////////////////////////////////
                             PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mints an NFT
     * @param projectId The ID of the project to mint the NFT for
     */
    function mint(uint256 projectId) external payable {
        if (msg.value < price) {
            revert InsufficientFunds();
        }
        _mint(msg.sender, projectId, 1, bytes(""));
    }

    /**
     * @notice Mints multiple NFTs
     * @param projectId The ID of the project to mint the NFT for
     * @param amount The amount of NFTs to mint
     */
    function mintMany(uint256 projectId, uint256 amount) external payable {
        if (msg.value < price * amount) {
            revert InsufficientFunds();
        }
        _mint(msg.sender, projectId, amount, bytes(""));
    }

    /**
     * @notice Transfers revenue from the contract to the revenue recipient
     */
    function withdraw() external {
        uint256 balance = address(this).balance;
        Address.sendValue(revenueRecipient, balance);
        emit Withdrew(revenueRecipient, balance);
    }

    /**
     * @notice Returns the URI of the NFT
     * @dev Returns the corresponding URI on the projects contract
     * @param projectId The ID of the project to get the NFT URI for
     */
    function uri(
        uint256 projectId
    ) public view virtual override returns (string memory) {
        return projects.tokenURI(projectId);
    }

    /**
     * @notice Returns the contract URI
     */
    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    /**
     * @notice Returns whether or not the contract supports an interface
     * @param interfaceId The ID of the interface to check
     * @inheritdoc IERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the price of the NFT
     * @param _price The price of the NFT in wei
     */
    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
        emit PriceSet(_price);
    }

    /**
     * @notice Sets the address that receives mint revenues
     * @dev Ideally a JBProjectPayer contract whose receive() function forwards revenues to a Juicebox Project
     * @param _revenueRecipient The address that receives mint revenues
     */
    function setRevenueRecipient(address _revenueRecipient) public onlyOwner {
        revenueRecipient = payable(_revenueRecipient);
        emit RevenueRecipientSet(_revenueRecipient);
    }

    /**
     * @notice Sets the address of the JBProjects contract from which to get the NFT URI
     * @param _JBProjects The address of the JBProjects contract
     */
    function setMetadata(address _JBProjects) public onlyOwner {
        projects = IERC721Metadata(_JBProjects);
        emit MetadataSet(_JBProjects);
    }

    /**
     * @notice Sets the contract URI
     * @param _contractUri The URI of the contract metadata
     */
    function setContractUri(string memory _contractUri) public onlyOwner {
        contractUri = _contractUri;
        emit ContractUriSet(_contractUri);
    }
}