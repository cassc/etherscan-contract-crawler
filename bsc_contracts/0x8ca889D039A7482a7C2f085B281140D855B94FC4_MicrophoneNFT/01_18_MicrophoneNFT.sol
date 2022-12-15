// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "./interfaces/IManagement.sol";
import "./interfaces/IMicrophoneNFT.sol";
import "./interfaces/IBreeding.sol";

contract MicrophoneNFT is IMicrophoneNFT, ERC721EnumerableUpgradeable {
    string private baseTokenURI;

    IManagement public management;

    modifier onlyAdmin() {
        require(_msgSender() == management.admin(), "Unauthorized: Admin only");
        _;
    }

    modifier AddressZero(address _addr) {
        require(_addr != address(0), "Set address to zero");
        _;
    }

    event NewMicrophone(
        address indexed owner,
        uint256 microphoneId,
        uint8 _body,
        uint8 _head,
        uint8 _class
    );

    function init(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        address _management
    ) external AddressZero(_management) initializer {
        __ERC721_init(_name, _symbol);
        __ERC721Enumerable_init();

        baseTokenURI = _baseTokenURI;
        management = IManagement(_management);
    }

    /**
        @notice Update new management
        @param _newManagement address of new management
        @dev Caller must be ADMIN
     */
    function updateManagement(address _newManagement)
        external
        AddressZero(_newManagement)
        onlyAdmin
    {
        management = IManagement(_newManagement);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _uri) external onlyAdmin {
        baseTokenURI = _uri;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    function mint(
        uint8 _body,
        uint8 _head,
        uint8 _kind,
        uint8 _class,
        address _to
    ) external returns (uint256) {
        address msgSender = _msgSender();
        require(
            msgSender == management.minter() ||
                msgSender == management.lootBox(),
            "Unauthorized: Minter or LootBox contract only"
        );

        uint256 microphoneId = IBreeding(management.breeding()).addMicro(
            _body,
            _head,
            _kind,
            _class
        );

        // emit the event
        emit NewMicrophone(_to, microphoneId, _body, _head, _class);

        _safeMint(_to, microphoneId);
        return microphoneId;
    }

    /**
        @dev Transfers a microphone owned by this contract to the specified address.
         Used to rescue lost superpasses. (There is no "proper" flow where this contract
         should be the owner of any micros. This function exists for us to reassign
         the ownership of micros that users may have accidentally sent to our address.)
        @notice Caller must be ADMIN
        @param _microphoneId - ID of Microphone
        @param _recipient - Address to receive the lost pass
     */
    function rescueLostMicrophone(uint256 _microphoneId, address _recipient)
        external
        onlyAdmin
    {
        require(
            ownerOf(_microphoneId) == address(this),
            "Contract doesn't own this microphone"
        );
        _safeTransfer(address(this), _recipient, _microphoneId, "");
    }
}