// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../utils/KeysMapping.sol";
import "../interfaces/IDispatcher.sol";

contract NotesNft is ERC721, AccessControl {
    using Address for address;
    using Strings for uint256;

    struct Loan {
        address loanCoordinator;
        uint256 loanId;
    }

    bytes32 public constant LOAN_COORDINATOR_ROLE = keccak256("LOAN_COORDINATOR_ROLE");
    bytes32 public constant BASE_URI_ROLE = keccak256("BASE_URI_ROLE");

    IDispatcher public immutable hub;

    mapping(uint256 => Loan) public loans;

    string public baseURI;

    constructor(
        address _admin,
        address _dispatcher,
        address _loanCoordinator,
        string memory _name,
        string memory _symbol,
        string memory _customBaseURI
    ) ERC721(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(BASE_URI_ROLE, _admin);
        _setupRole(LOAN_COORDINATOR_ROLE, _loanCoordinator);
        _setBaseURI(_customBaseURI);
        hub = IDispatcher(_dispatcher);
    }

    function setLoanCoordinator(address _account) external {
        grantRole(LOAN_COORDINATOR_ROLE, _account);
    }

    function mint(
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external onlyRole(LOAN_COORDINATOR_ROLE) {
        require(_data.length > 0, "data must contain loanId");
        uint256 loanId = abi.decode(_data, (uint256));
        loans[_tokenId] = Loan({loanCoordinator: msg.sender, loanId: loanId});
        _safeMint(_to, _tokenId, _data);
    }

    function burn(uint256 _tokenId) external onlyRole(LOAN_COORDINATOR_ROLE) {
        delete loans[_tokenId];
        _burn(_tokenId);
    }

    function setBaseURI(string memory _customBaseURI) external onlyRole(BASE_URI_ROLE) {
        _setBaseURI(_customBaseURI);
    }

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    function _setBaseURI(string memory _customBaseURI) internal virtual {
        baseURI = bytes(_customBaseURI).length > 0
            ? string(abi.encodePacked(_customBaseURI, _getChainID().toString(), "/"))
            : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _getChainID() internal view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }
}