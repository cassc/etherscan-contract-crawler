// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

import { IERC20Impl, IERC20Upgradeable }     from "./interfaces/IERC20Impl.sol";
import { IERC721Impl, IERC721Upgradeable }   from "./interfaces/IERC721Impl.sol";
import { IERC1155Impl, IERC1155Upgradeable } from "./interfaces/IERC1155Impl.sol";

contract TokensFactory {
    using Clones for address;
    uint256 public counter;

    event ERC20TokenCreated(
        IERC20Upgradeable indexed erc20Token,
        uint256 indexed counter,
        string tokenName,
        string tokenSymbol
    );
    event ERC721TokenCreated(
        IERC721Upgradeable indexed erc721Token,
        uint256 indexed counter,
        string tokenName,
        string tokenSymbol
    );
    event ERC1155TokenCreated(
        IERC1155Upgradeable indexed erc1155Token,
        uint256 indexed counter,
        string uri
    );

    // tokens implementation contracts for factory
    address public immutable erc20TokenImplementation;
    address public immutable erc721TokenImplementation;
    address public immutable erc1155TokenImplementation;

    /**
     * @notice Get the address of implementation contracts instance.
     */
    constructor(
        address _erc20TokenImplementation,
        address _erc721TokenImplementation,
        address _erc1155TokenImplementation
    ) {
        erc20TokenImplementation = _erc20TokenImplementation;
        erc721TokenImplementation = _erc721TokenImplementation;
        erc1155TokenImplementation = _erc1155TokenImplementation;
    }

    /**
     * @notice Get the counterfactual address of ERC20 token implementation
     */
    function determineERC20TokenAddress(
        uint256 _counter,
        string memory _name,
        string memory _symbol
    ) external view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(_counter, _name, _symbol));
        return
            Clones.predictDeterministicAddress(
                erc20TokenImplementation,
                salt,
                address(this)
            );
    }

    /**
     * @notice Get the counterfactual address of ERC721 token implementation
     */
    function determineERC721TokenAddress(
        uint256 _counter,
        string memory _name,
        string memory _symbol
    ) external view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(_counter, _name, _symbol));
        return
            Clones.predictDeterministicAddress(
                erc721TokenImplementation,
                salt,
                address(this)
            );
    }

    /**
     * @notice Get the counterfactual address of ERC1155 token implementation
     */
    function determineERC1155TokenAddress(uint256 _counter, string memory _uri)
        external
        view
        returns (address)
    {
        bytes32 salt = keccak256(abi.encodePacked(_counter, _uri));
        return
            Clones.predictDeterministicAddress(
                erc1155TokenImplementation,
                salt,
                address(this)
            );
    }

    /**
     * @notice Clones new ERC20 tokens - { returns ERC20 tokens address typecasted to IERC20Upgradeable }
     *
     * @param _tokenName is the name for ERC20
     * @param _tokenSymbol is the symbol for ERC20
     */
    function createERC20Token(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _tokenDecimals
    ) external returns (IERC20Upgradeable erc20Token) {
        counter++;
        bytes32 salt = keccak256(
            abi.encodePacked(counter, _tokenName, _tokenSymbol)
        );
        IERC20Impl newERC20Token = IERC20Impl(
            erc20TokenImplementation.cloneDeterministic(salt)
        );
        newERC20Token.__ERC20Impl_init(
            _tokenName,
            _tokenSymbol,
            _tokenDecimals,
            msg.sender
        );
        erc20Token = IERC20Upgradeable(newERC20Token);
        emit ERC20TokenCreated(erc20Token, counter, _tokenSymbol, _tokenName);
    }

    /**
     * @notice Clones new ERC721 tokens - { returns ERC721 tokens address typecasted to IERC721Upgradeable }
     *
     * @param _tokenName is the name for ERC721
     * @param _tokenSymbol is the symbol for ERC721
     */
    function createERC721Token(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _baseUri
    ) external returns (IERC721Upgradeable erc721Token) {
        counter++;
        bytes32 salt = keccak256(
            abi.encodePacked(counter, _tokenName, _tokenSymbol)
        );
        IERC721Impl newERC721Token = IERC721Impl(
            erc721TokenImplementation.cloneDeterministic(salt)
        );
        newERC721Token.__ERC721Impl_init(
            _tokenName,
            _tokenSymbol,
            _baseUri,
            msg.sender
        );
        erc721Token = IERC721Upgradeable(newERC721Token);
        emit ERC721TokenCreated(erc721Token, counter, _tokenSymbol, _tokenName);
    }

    /**
     * @notice Clones new ERC1155 tokens - { returns ERC1155 tokens address typecasted to IERC1155Upgradeable }
     *
     * @param _uri is the metadata uri for ERC1155 tokens
     */
    function createERC1155Token(string memory _uri)
        external
        returns (IERC1155Upgradeable erc1155Token)
    {
        counter++;
        bytes32 salt = keccak256(abi.encodePacked(counter, _uri));
        IERC1155Impl newERC1155Token = IERC1155Impl(
            erc1155TokenImplementation.cloneDeterministic(salt)
        );
        newERC1155Token.__ERC1155Impl_init(_uri, msg.sender);
        erc1155Token = IERC1155Upgradeable(newERC1155Token);

        emit ERC1155TokenCreated(erc1155Token, counter, _uri);
    }
}