// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import "./openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/ICapsule.sol";
import "./CapsuleMinterStorage.sol";
import "./access/Governable.sol";
import "./Errors.sol";

contract CapsuleMinter is
    Initializable,
    Governable,
    ReentrancyGuard,
    IERC721Receiver,
    ERC1155Holder,
    CapsuleMinterStorageV2
{
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant VERSION = "1.1.0";
    uint256 public constant TOKEN_TYPE_LIMIT = 100;
    uint256 internal constant MAX_CAPSULE_MINT_TAX = 0.1 ether;

    event AddedToWhitelist(address indexed user);
    event RemovedFromWhitelist(address indexed user);
    event FlushedTaxAmount(uint256 taxAmount);
    event CapsuleMintTaxUpdated(uint256 oldMintTax, uint256 newMintTax);
    event SimpleCapsuleMinted(address indexed account, address indexed capsule, uint256 capsuleId);
    event SimpleCapsuleBurnt(address indexed account, address indexed capsule, uint256 capsuleId);
    event SingleERC20CapsuleMinted(
        address indexed account,
        address indexed capsule,
        address indexed token,
        uint256 amount,
        uint256 capsuleId
    );
    event SingleERC20CapsuleBurnt(
        address indexed account,
        address indexed capsule,
        address indexed token,
        uint256 amount,
        uint256 capsuleId
    );
    event SingleERC721CapsuleMinted(
        address indexed account,
        address indexed capsule,
        address indexed token,
        uint256 id,
        uint256 capsuleId
    );
    event SingleERC721CapsuleBurnt(
        address indexed account,
        address indexed capsule,
        address indexed token,
        uint256 id,
        uint256 capsuleId
    );

    event MultiERC20CapsuleMinted(
        address indexed account,
        address indexed capsule,
        address[] tokens,
        uint256[] amounts,
        uint256 capsuleId
    );
    event MultiERC20CapsuleBurnt(
        address indexed account,
        address indexed capsule,
        address[] tokens,
        uint256[] amounts,
        uint256 capsuleId
    );
    event MultiERC721CapsuleMinted(
        address indexed account,
        address indexed capsule,
        address[] tokens,
        uint256[] ids,
        uint256 capsuleId
    );
    event MultiERC721CapsuleBurnt(
        address indexed account,
        address indexed capsule,
        address[] tokens,
        uint256[] ids,
        uint256 capsuleId
    );

    event MultiERC1155CapsuleMinted(
        address indexed account,
        address indexed capsule,
        address[] tokens,
        uint256[] ids,
        uint256[] amounts,
        uint256 capsuleId
    );
    event MultiERC1155CapsuleBurnt(
        address indexed account,
        address indexed capsule,
        address[] tokens,
        uint256[] ids,
        uint256[] amounts,
        uint256 capsuleId
    );

    function initialize(address _factory) external initializer {
        require(_factory != address(0), Errors.ZERO_ADDRESS);
        __Governable_init();
        factory = ICapsuleFactory(_factory);
        capsuleMintTax = 0.001 ether;
    }

    modifier checkTaxRequirement() {
        if (!mintWhitelist.contains(_msgSender())) {
            require(msg.value == capsuleMintTax, Errors.INCORRECT_TAX_AMOUNT);
        }
        _;
    }

    modifier onlyValidCapsuleCollections(address _capsule) {
        require(factory.isCapsule(_capsule), Errors.NOT_CAPSULE);
        _;
    }

    modifier onlyCollectionMinter(address _capsule) {
        require(factory.isCapsule(_capsule), Errors.NOT_CAPSULE);
        require(ICapsule(_capsule).isCollectionMinter(_msgSender()), Errors.NOT_COLLECTION_MINTER);
        _;
    }

    /******************************************************************************
     *                              Read functions                                *
     *****************************************************************************/

    // return the owner of a Capsule by id
    function getCapsuleOwner(address _capsule, uint256 _id) external view returns (address) {
        return ICapsule(_capsule).ownerOf(_id);
    }

    /// @notice Get list of mint whitelisted address
    function getMintWhitelist() external view returns (address[] memory) {
        return mintWhitelist.values();
    }

    function multiERC20Capsule(address _capsule, uint256 _id) external view returns (MultiERC20Capsule memory _data) {
        return _multiERC20Capsule[_capsule][_id];
    }

    function multiERC721Capsule(address _capsule, uint256 _id) external view returns (MultiERC721Capsule memory _data) {
        return _multiERC721Capsule[_capsule][_id];
    }

    function multiERC1155Capsule(address _capsule, uint256 _id)
        external
        view
        returns (MultiERC1155Capsule memory _data)
    {
        return _multiERC1155Capsule[_capsule][_id];
    }

    /// @notice Return whether given address is mint whitelisted or not
    function isMintWhitelisted(address _user) external view returns (bool) {
        return mintWhitelist.contains(_user);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        // `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
        return 0x150b7a02;
    }

    // ERC1155 Receiving occurs in the ERC1155Holder contract

    /******************************************************************************
     *                             Write functions                                *
     *****************************************************************************/
    function mintSimpleCapsule(
        address _capsule,
        string calldata _uri,
        address _receiver
    ) external payable nonReentrant onlyCollectionMinter(_capsule) checkTaxRequirement {
        // Mark id as a simple NFT
        uint256 _capsuleId = ICapsule(_capsule).counter();
        isSimpleCapsule[_capsule][_capsuleId] = true;
        ICapsule(_capsule).mint(_receiver, _uri);
        emit SimpleCapsuleMinted(_receiver, _capsule, _capsuleId);
    }

    function burnSimpleCapsule(address _capsule, uint256 _capsuleId)
        external
        nonReentrant
        onlyValidCapsuleCollections(_capsule)
    {
        require(isSimpleCapsule[_capsule][_capsuleId], Errors.NOT_SIMPLE_CAPSULE);
        delete isSimpleCapsule[_capsule][_capsuleId];
        // We do not have to store the token uri in a local variable - we are emitting an event before burn
        emit SimpleCapsuleBurnt(_msgSender(), _capsule, _capsuleId);
        ICapsule(_capsule).burn(_msgSender(), _capsuleId);
    }

    function mintSingleERC20Capsule(
        address _capsule,
        address _token,
        uint256 _amount,
        string calldata _uri,
        address _receiver
    ) external payable nonReentrant onlyCollectionMinter(_capsule) checkTaxRequirement {
        require(_amount > 0, Errors.INVALID_TOKEN_AMOUNT);
        require(_token != address(0), Errors.INVALID_TOKEN_ADDRESS);

        // get the current top counter
        uint256 _capsuleId = ICapsule(_capsule).counter();

        // transfer tokens from caller to contract
        uint256 _actualAmount = _depositToken(IERC20(_token), _msgSender(), _amount);

        // then, add user data into the contract (tie NFT to value):
        // - set the ID of the Capsule NFT at counter to map to the passed in tokenAddress
        // - set the ID of the Capsule NFT at counter to map to the passed in tokenAmount
        singleERC20Capsule[_capsule][_capsuleId].tokenAddress = _token;
        singleERC20Capsule[_capsule][_capsuleId].tokenAmount = _actualAmount;
        // lastly, mint the Capsule NFT (minted at the current counter (obtained above as id))
        ICapsule(_capsule).mint(_receiver, _uri);

        emit SingleERC20CapsuleMinted(_receiver, _capsule, _token, _actualAmount, _capsuleId);
    }

    function burnSingleERC20Capsule(address _capsule, uint256 _capsuleId)
        external
        nonReentrant
        onlyValidCapsuleCollections(_capsule)
    {
        SingleERC20Capsule memory _capsuleData = singleERC20Capsule[_capsule][_capsuleId];
        // If there is no token amount in stored data then provided id is not ERC20 Capsule id
        require(_capsuleData.tokenAmount > 0, Errors.NOT_ERC20_CAPSULE_ID);

        // get the token address held at the Capsule NFT id
        address heldTokenAddress = _capsuleData.tokenAddress;
        // get the amount of tokens held by the Capsule NFT id
        uint256 tokensHeldById = _capsuleData.tokenAmount;
        // then, delete the Capsule NFT data at id
        delete singleERC20Capsule[_capsule][_capsuleId];

        // burn the Capsule NFT at id
        ICapsule(_capsule).burn(_msgSender(), _capsuleId);

        // send tokens back to the user
        IERC20(heldTokenAddress).safeTransfer(_msgSender(), tokensHeldById);
        emit SingleERC20CapsuleBurnt(_msgSender(), _capsule, heldTokenAddress, tokensHeldById, _capsuleId);
    }

    function mintSingleERC721Capsule(
        address _capsule,
        address _token,
        uint256 _id,
        string calldata _uri,
        address _receiver
    ) external payable nonReentrant onlyCollectionMinter(_capsule) checkTaxRequirement {
        // get the current top counter
        uint256 _capsuleId = ICapsule(_capsule).counter();

        // transfer input NFT to contract. safeTransferFrom does check that from, _msgSender in this case, is owner.
        IERC721(_token).safeTransferFrom(_msgSender(), address(this), _id);

        // check that the contract owns that NFT
        require(IERC721(_token).ownerOf(_id) == address(this), Errors.NOT_NFT_OWNER);

        // then, add user data into the contract (tie Capsule NFT to input token):
        // - set the ID of the Capsule NFT at counter to map to the passed in tokenAddress
        // - set the ID of the Capsule NFT at counter to map to the passed in id
        singleERC721Capsule[_capsule][_capsuleId].tokenAddress = _token;
        singleERC721Capsule[_capsule][_capsuleId].id = _id;
        // lastly, mint the Capsule NFT
        ICapsule(_capsule).mint(_receiver, _uri);

        emit SingleERC721CapsuleMinted(_receiver, _capsule, _token, _id, _capsuleId);
    }

    function burnSingleERC721Capsule(address _capsule, uint256 _capsuleId)
        external
        nonReentrant
        onlyValidCapsuleCollections(_capsule)
    {
        SingleERC721Capsule memory _capsuleData = singleERC721Capsule[_capsule][_capsuleId];
        // If there is no token address in stored data then provided id is not ERC721 Capsule id
        require(_capsuleData.tokenAddress != address(0), Errors.NOT_ERC721_CAPSULE_ID);

        // get the token address held at the Capsule NFT id
        address heldTokenAddress = _capsuleData.tokenAddress;
        // get the amount of token Id held by the Capsule NFT id
        uint256 tokenId = _capsuleData.id;
        // then, delete the Capsule NFT data at id
        delete singleERC721Capsule[_capsule][_capsuleId];

        // burn the Capsule NFT
        ICapsule(_capsule).burn(_msgSender(), _capsuleId);
        // send token back to the user
        IERC721(heldTokenAddress).safeTransferFrom(address(this), _msgSender(), tokenId);

        emit SingleERC721CapsuleBurnt(_msgSender(), _capsule, heldTokenAddress, tokenId, _capsuleId);
    }

    function mintMultiERC20Capsule(
        address _capsule,
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        string calldata _uri,
        address _receiver
    ) external payable nonReentrant onlyCollectionMinter(_capsule) checkTaxRequirement {
        uint256 _len = _tokens.length;

        require(_len > 0 && _len <= TOKEN_TYPE_LIMIT, Errors.INVALID_TOKEN_ARRAY_LENGTH);
        require(_len == _amounts.length, Errors.LENGTH_MISMATCH);

        // get the current top counter
        uint256 _capsuleId = ICapsule(_capsule).counter();
        // Some tokens, like USDT, may have a transfer fee, so we want to record actual transfer amount
        uint256[] memory _actualAmounts = new uint256[](_len);
        // loop assumes that the token address and amount is mapped to the same index in both arrays
        // meaning: the user is sending _amounts[0] of _tokens[0]
        for (uint256 i; i < _len; i++) {
            address _token = _tokens[i];
            uint256 _amount = _amounts[i];

            require(_amount > 0, Errors.INVALID_TOKEN_AMOUNT);
            require(_token != address(0), Errors.INVALID_TOKEN_ADDRESS);

            // transfer tokens from caller to contract
            _actualAmounts[i] = _depositToken(IERC20(_token), _msgSender(), _amount);
        }

        // then add user data into the contract (tie Capsule NFT to input):
        _multiERC20Capsule[_capsule][_capsuleId].tokenAddresses = _tokens;
        _multiERC20Capsule[_capsule][_capsuleId].tokenAmounts = _actualAmounts;

        // lastly, mint the Capsule NFT
        ICapsule(_capsule).mint(_receiver, _uri);

        emit MultiERC20CapsuleMinted(_receiver, _capsule, _tokens, _actualAmounts, _capsuleId);
    }

    function burnMultiERC20Capsule(address _capsule, uint256 _capsuleId)
        external
        nonReentrant
        onlyValidCapsuleCollections(_capsule)
    {
        address[] memory tokens = _multiERC20Capsule[_capsule][_capsuleId].tokenAddresses;
        uint256[] memory amounts = _multiERC20Capsule[_capsule][_capsuleId].tokenAmounts;
        // If there is no tokens in stored data then provided id is not ERC20 Capsule id
        require(tokens.length > 0, Errors.NOT_ERC20_CAPSULE_ID);

        // then, delete the Capsule NFT data at id
        delete _multiERC20Capsule[_capsule][_capsuleId];

        // burn the Capsule NFT
        ICapsule(_capsule).burn(_msgSender(), _capsuleId);

        for (uint256 i; i < tokens.length; i++) {
            // send tokens back to the user
            IERC20(tokens[i]).safeTransfer(_msgSender(), amounts[i]);
        }

        emit MultiERC20CapsuleBurnt(_msgSender(), _capsule, tokens, amounts, _capsuleId);
    }

    function mintMultiERC721Capsule(
        address _capsule,
        address[] calldata _tokens,
        uint256[] calldata _ids,
        string calldata _uri,
        address _receiver
    ) external payable nonReentrant onlyCollectionMinter(_capsule) checkTaxRequirement {
        uint256 _len = _tokens.length;

        require(_len > 0 && _len <= TOKEN_TYPE_LIMIT, Errors.INVALID_TOKEN_ARRAY_LENGTH);
        require(_len == _ids.length, Errors.LENGTH_MISMATCH);

        // get the current top counter
        uint256 _capsuleId = ICapsule(_capsule).counter();

        // loop assumes that the token address and id are mapped to the same index in both arrays
        // meaning: the user is sending _ids[0] of _tokens[0]
        for (uint256 i; i < _len; i++) {
            address _token = _tokens[i];
            uint256 _id = _ids[i];

            // no require check necessary for id
            require(_token != address(0), Errors.INVALID_TOKEN_ADDRESS);

            // transfer token to contract, safeTransferFrom does check from is the owner of id
            IERC721(_token).safeTransferFrom(_msgSender(), address(this), _id);

            // check the contract owns that NFT
            require(IERC721(_token).ownerOf(_id) == address(this), Errors.NOT_NFT_OWNER);
        }

        // then, add user data into the contract (tie Capsule NFT to input):
        // - set the ID of the NFT (counter) to map to the passed in tokenAddresses
        // - set the ID of the NFT (counter) to map to the passed in ids
        _multiERC721Capsule[_capsule][_capsuleId].tokenAddresses = _tokens;
        _multiERC721Capsule[_capsule][_capsuleId].ids = _ids;

        // lastly, mint the Capsule NFT
        ICapsule(_capsule).mint(_receiver, _uri);

        emit MultiERC721CapsuleMinted(_receiver, _capsule, _tokens, _ids, _capsuleId);
    }

    function burnMultiERC721Capsule(address _capsule, uint256 _capsuleId)
        external
        nonReentrant
        onlyValidCapsuleCollections(_capsule)
    {
        address[] memory tokens = _multiERC721Capsule[_capsule][_capsuleId].tokenAddresses;
        uint256[] memory ids = _multiERC721Capsule[_capsule][_capsuleId].ids;
        // If there is no tokens in stored data then provided id is not ERC721 Capsule id
        require(tokens.length > 0, Errors.NOT_ERC721_CAPSULE_ID);

        // then, delete the Capsule NFT data at id
        delete _multiERC721Capsule[_capsule][_capsuleId];

        // burn the Capsule NFT
        ICapsule(_capsule).burn(_msgSender(), _capsuleId);

        for (uint256 i; i < tokens.length; i++) {
            // send tokens back to the user
            IERC721(tokens[i]).safeTransferFrom(address(this), _msgSender(), ids[i]);
        }

        emit MultiERC721CapsuleBurnt(_msgSender(), _capsule, tokens, ids, _capsuleId);
    }

    function mintMultiERC1155Capsule(
        address _capsule,
        address[] calldata _tokens,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        string calldata _uri,
        address _receiver
    ) external payable nonReentrant onlyCollectionMinter(_capsule) checkTaxRequirement {
        uint256 _len = _tokens.length;
        require(_len > 0 && _len <= TOKEN_TYPE_LIMIT, Errors.INVALID_TOKEN_ARRAY_LENGTH);
        require(_len == _ids.length && _len == _amounts.length, Errors.LENGTH_MISMATCH);

        // loop assumes that the token address, id and amount are mapped to the same index in both arrays
        // meaning: the user is sending _amounts[0] of _tokens[0] at _ids[0]
        for (uint256 i; i < _len; i++) {
            address _token = _tokens[i];
            uint256 _id = _ids[i];

            // no require check necessary for id
            require(_token != address(0), Errors.INVALID_TOKEN_ADDRESS);
            uint256 _balanceBefore = IERC1155(_token).balanceOf(address(this), _id);
            // transfer token to contract, safeTransferFrom does check from is the owner of id
            IERC1155(_token).safeTransferFrom(_msgSender(), address(this), _id, _amounts[i], "");

            // check that this contract owns the ERC-1155 token
            require(
                IERC1155(_token).balanceOf(address(this), _id) == _balanceBefore + _amounts[i],
                Errors.NOT_NFT_OWNER
            );
        }

        uint256 _capsuleId = ICapsule(_capsule).counter();
        // then, add user data into the contract (tie Capsule NFT to input):
        // - set the ID of the NFT (counter) to map to the passed in tokenAddresses
        // - set the ID of the NFT (counter) to map to the passed in ids
        // - set the ID of the NFT (counter) to map to the passed in amounts (1155)
        _multiERC1155Capsule[_capsule][_capsuleId] = MultiERC1155Capsule({
            tokenAddresses: _tokens,
            ids: _ids,
            tokenAmounts: _amounts
        });

        // lastly, mint the Capsule NFT
        ICapsule(_capsule).mint(_receiver, _uri);
        emit MultiERC1155CapsuleMinted(_receiver, _capsule, _tokens, _ids, _amounts, _capsuleId);
    }

    function burnMultiERC1155Capsule(address _capsule, uint256 _capsuleId)
        external
        nonReentrant
        onlyValidCapsuleCollections(_capsule)
    {
        address[] memory _tokens = _multiERC1155Capsule[_capsule][_capsuleId].tokenAddresses;
        uint256[] memory _ids = _multiERC1155Capsule[_capsule][_capsuleId].ids;
        uint256[] memory _amounts = _multiERC1155Capsule[_capsule][_capsuleId].tokenAmounts;
        // If there is no tokens in stored data then provided id is not ERC1155 Capsule id
        require(_tokens.length > 0, Errors.NOT_ERC1155_CAPSULE_ID);

        // then, delete the Capsule NFT data at id
        delete _multiERC1155Capsule[_capsule][_capsuleId];

        // burn the Capsule NFT
        ICapsule(_capsule).burn(_msgSender(), _capsuleId);

        for (uint256 i; i < _tokens.length; i++) {
            // send tokens back to the user
            IERC1155(_tokens[i]).safeTransferFrom(address(this), _msgSender(), _ids[i], _amounts[i], "");
        }

        emit MultiERC1155CapsuleBurnt(_msgSender(), _capsule, _tokens, _ids, _amounts, _capsuleId);
    }

    /******************************************************************************
     *                            Governor functions                              *
     *****************************************************************************/
    function flushTaxAmount() external {
        address _taxCollector = factory.taxCollector();
        require(_msgSender() == governor || _msgSender() == _taxCollector, Errors.UNAUTHORIZED);
        uint256 _taxAmount = address(this).balance;
        emit FlushedTaxAmount(_taxAmount);
        Address.sendValue(payable(_taxCollector), _taxAmount);
    }

    function addToWhitelist(address _user) external onlyGovernor {
        require(_user != address(0), Errors.ZERO_ADDRESS);
        require(mintWhitelist.add(_user), Errors.ADDRESS_ALREADY_EXIST);
        emit AddedToWhitelist(_user);
    }

    function removeFromWhitelist(address _user) external onlyGovernor {
        require(_user != address(0), Errors.ZERO_ADDRESS);
        require(mintWhitelist.remove(_user), Errors.ADDRESS_DOES_NOT_EXIST);
        emit RemovedFromWhitelist(_user);
    }

    /// @notice update Capsule NFT mint tax
    function updateCapsuleMintTax(uint256 _newTax) external onlyGovernor {
        require(_newTax <= MAX_CAPSULE_MINT_TAX, Errors.INCORRECT_TAX_AMOUNT);
        require(_newTax != capsuleMintTax, Errors.SAME_AS_EXISTING);
        emit CapsuleMintTaxUpdated(capsuleMintTax, _newTax);
        capsuleMintTax = _newTax;
    }

    /******************************************************************************
     *                            Internal functions                              *
     *****************************************************************************/
    function _depositToken(
        IERC20 _token,
        address _depositor,
        uint256 _amount
    ) internal returns (uint256 _actualAmount) {
        uint256 _balanceBefore = _token.balanceOf(address(this));
        _token.safeTransferFrom(_depositor, address(this), _amount);
        _actualAmount = _token.balanceOf(address(this)) - _balanceBefore;
        require(_actualAmount > 0, Errors.INVALID_TOKEN_AMOUNT);
    }
}