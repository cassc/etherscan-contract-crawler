pragma solidity ^0.8.0;

import "@routerprotocol/router-crosstalk/contracts/RouterCrossTalk.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract CrossChainERC20 is ERC20, AccessControl, RouterCrossTalk {
    uint256 private _crossChainGasLimit;
    uint256 private _crossChainGasPrice;
    uint256 internal _totalmintsupply = 1000000000*(10**18);

    constructor(address _genericHandler)
        RouterCrossTalk(_genericHandler)
        ERC20("Test", "TST")
        AccessControl()
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _mint(msg.sender,_totalmintsupply);
    }

    function mint(address _to, uint256 _amt)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _mint(_to, _amt);
    }

    function burn(address _to, uint256 _amt)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _burn(_to, _amt);
    }

    // Admin Functions for Cross Talk Start

    /**
     * @notice setLinker Used to set address of linker, this can only be set by Admin
     * @param _addr Address of the linker
     */
    function setLinker(address _addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setLink(_addr);
    }

    /**
     * @notice setFeesToken To set the fee token in which fee is desired to be charged, this can only be set by Admin
     * @param _feeToken Address of the feeToken
     */
    function setFeesToken(address _feeToken)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        setFeeToken(_feeToken);
    }

    /**
     * @notice _approveFees To approve handler to deduct fees from source contract, this can only be set by Admin
     * @param _feeToken Address of the feeToken
     * @param _amount Amount to be approved
     */
    function _approveFees(address _feeToken, uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        approveFees(_feeToken, _amount);
    }

    /**
     * @notice setCrossChainGasLimit Used to set CrossChainGasLimit, this can only be set by Admin
     * @param _gasLimit Amount of gasLimit that is to be set
     */
    function setCrossChainGasLimit(uint256 _gasLimit)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _crossChainGasLimit = _gasLimit;
    }

    /**
     * @notice fetchCrossChainGasLimit Used to fetch CrossChainGasLimit
     * @return crossChainGasLimit that is set
     */
    function fetchCrossChainGasLimit() external view returns (uint256) {
        return _crossChainGasLimit;
    }

    /**
     * @notice setCrossChainGasPrice Used to set CrossChainGasPrice, this can only be set by Admin
     * @param _gasPrice Amount of gasPrice that is to be set
     */
    function setCrossChainGasPrice(uint256 _gasPrice)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _crossChainGasPrice = _gasPrice;
    }

    /**
     * @notice fetchCrossChainGasPrice Used to fetch CrossChainGasPrice
     * @return crossChainGasPrice that is set
     */
    function fetchCrossChainGasPrice() external view returns (uint256) {
        return _crossChainGasPrice;
    }

    // Admin Functions for Cross Talk End

    // Cross Chain ERC20 Fx Start

    // Send

    /**
     * @notice transferCrossChain This function burns "_amt" of tokens from caller's account on source side
     * @notice And initialise the crosschain request to mint on destination side
     * @param _chainID Destination chain id where tokens are desired to be minted
     * @param _to Address of the recipient of tokens on destination chain
     * @param _amt Amount of tokens to be burnt on source and minted on destination
     */
    function transferCrossChain(
        uint8 _chainID,
        address _to,
        uint256 _amt
    ) external returns (bool, bytes32) {
        _burn(msg.sender, _amt);
        (bool success, bytes32 hash) = _sendCrossChain(_chainID, _to, _amt);
        return (success, hash);
    }

    /**
     * @notice _sendCrossChain This is an internal function to generate a cross chain communication request
     */
    function _sendCrossChain(
        uint8 _chainID,
        address _to,
        uint256 _amt
    ) internal returns (bool, bytes32) {
        bytes4 _selector = bytes4(
            keccak256("receiveCrossChain(address,uint256)")
        );
        bytes memory _data = abi.encode(_to, _amt);
        (bool success, bytes32 hash) = routerSend(
            _chainID,
            _selector,
            _data,
            _crossChainGasLimit,
            _crossChainGasPrice
        );
        require(success == true, "unsuccessful");
        return (success, hash);
    }

    //Send

    // Receive

    /**
     * @notice _routerSyncHandler This is an internal function to control the handling of various selectors and its corresponding
     * @param _selector Selector to interface.
     * @param _data Data to be handled.
     */
    function _routerSyncHandler(bytes4 _selector, bytes memory _data)
        internal
        virtual
        override
        returns (bool, bytes memory)
    {
        (address _to, uint256 _amt) = abi.decode(_data, (address, uint256));
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodeWithSelector(_selector, _to, _amt)
        );
        return (success, returnData);
    }

    /**
     * @notice receiveCrossChain Creates `_amt` tokens to `_to` on the destination chain
     *
     * NOTE: It can only be called by current contract.
     */
    function receiveCrossChain(address _to, uint256 _amt) external isSelf {
        _mint(_to, _amt);
    }

    // Receive

    /**
     * @notice replayTransferCrossChain Used to replay the transaction if it failed due to low gaslimit or gasprice
     * @param hash Hash returned by `transferCrossChain` function
     * @param crossChainGasLimit Higher gasLimit
     * @param crossChainGasPrice Higher gasPrice
     */
    function replayTransferCrossChain(
        bytes32 hash,
        uint256 crossChainGasLimit,
        uint256 crossChainGasPrice
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        routerReplay(hash, crossChainGasLimit, crossChainGasPrice);
    }

    // Cross-chain ERC20 Fx End

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC20).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}