// SPDX-License-Identifier: MIT

/*********************************************************
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░  .░░░░░░░░░░░░░░░░░░░░░░░░.  ҹ░░░░░░░░░░░░*
*░░░░░░░░░░░░░  ∴░░░░░░░░░░░░░░░░░░`   ░░․  ░░∴   (░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º   ҹ  ░   (░░░░░░░░*
*░░░░░⁕  .░░░░░░░░░░░░░░░░░░░░░░░     ⁕..    .∴,    ⁕░░░░*
*░░░░░░  ∴░░░░░░░░░░░░░░░░░░░░░░░ҹ ,(º⁕ҹ     ․∴ҹ⁕(. ⁕░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º`  ․░  ⁕,   ░░░░░░░░*
*░░░░░,  .░░░░░░░░░░░░░░░░░░░░░░░░░`  ,░░⁕  ∴░░   `░░░░░░*
*░░░░░░⁕º░░░░░░░░░░░░░░⁕   ҹ░░░░░░░░░░░░░,  %░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░ҹ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░ҹ   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░º(░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*********************************************************/

pragma solidity ^0.8.6;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC20.sol";
import "./IERC20X.sol";
import "../../helpers/ECDSA.sol";

interface _IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
}

/// @title ERC-20 that can be held by NFTs
contract ERC20X is IERC20X, ERC20, ReentrancyGuard {
    using Address for address;
    using DynamicAddressLib for DynamicAddress;
    // when spell is cast, set amount of spellsCoin claimable by recipient contract

    mapping(address => mapping(uint256 => uint256)) internal _tokenBalances;
    mapping(address => mapping(uint256 => uint256)) public _nonces;
    mapping(address => uint256) public _addressNonces;

    // tokenOwner : tokenContract : tokenId : spender : amount
    mapping(address => mapping(address => mapping(uint256 => mapping(address => uint256))))
        private _tokenAllowances;
    uint256 _totalTokenHeldSupply;

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {}

    function balanceOf(address _contract, uint256 tokenId)
        external
        view
        override(IERC20X)
        returns (uint256)
    {
        return _tokenBalances[_contract][tokenId];
    }

    function totalTokenHeldSupply() public view virtual override(IERC20X) returns (uint256) {
        return _totalTokenHeldSupply;
    }

    function nonce(address _contract, uint256 tokenId)
        external
        view
        override(IERC20X)
        returns (uint256)
    {
        return _nonces[_contract][tokenId];
    }
    
    function nonce(address _address)
        external
        view
        returns (uint256)
    {
        return _addressNonces[_address];
    }

    function incrementNonce(address _contract, uint256 tokenId) external {
        address owner = _ownerOf(_contract, tokenId);
        require(msg.sender == owner, "SpellsCoin: Invalid withdrawal");
        _nonces[_contract][tokenId]++;
    }

    function transfer(
        address _contract,
        uint256 tokenId,
        uint256 amount
    ) public virtual override(IERC20X) returns (bool) {
        address owner = _msgSender();
        _transfer(owner, _contract, tokenId, amount);
        return true;
    }

    function transfer(
        address _contract,
        uint256 tokenId,
        address to,
        uint256 amount
    ) public virtual override(IERC20X) returns (bool) {
        address owner = _ownerOf(_contract, tokenId);
        require(
            msg.sender == owner,
            "SpellsCoin: transfer not initiated by token owner"
        );
        _transfer(_contract, tokenId, to, amount);
        return true;
    }

    function transfer(
        address _contract,
        uint256 tokenId,
        address toContract,
        uint256 toTokenId,
        uint256 amount
    ) public virtual override(IERC20X) returns (bool) {
        address owner = _ownerOf(_contract, tokenId);
        require(
            msg.sender == owner,
            "SpellsCoin: transfer not initiated by token owner"
        );
        _transfer(_contract, tokenId, toContract, toTokenId, amount);
        return true;
    }

    function transferFrom(
        address from,
        address toContract,
        uint256 toTokenId,
        uint256 amount
    ) public virtual override(IERC20X) returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, toContract, toTokenId, amount);
        return true;
    }

    function transferFrom(
        address _contract,
        uint256 tokenId,
        address to,
        uint256 amount
    ) public virtual override(IERC20X) returns (bool) {
        address spender = _msgSender();
        _spendAllowance(_contract, tokenId, spender, amount);
        _transfer(_contract, tokenId, to, amount);
        return true;
    }

    function transferFrom(
        address _contract,
        uint256 tokenId,
        address toContract,
        uint256 toTokenId,
        uint256 amount
    ) public virtual override(IERC20X) returns (bool) {
        address spender = _msgSender();
        _spendAllowance(_contract, tokenId, spender, amount);
        _transfer(_contract, tokenId, toContract, toTokenId, amount);
        return true;
    }

    function _transfer(
        address from,
        address toContract,
        uint256 toTokenId,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "SpellsCoin: transfer from the zero address");
        require(toContract != address(0), "SpellsCoin: transfer to the zero token");

        _beforeTokenTransfer(from, toContract, toTokenId, amount);

        _transfer(from, address(this), amount);
        _totalTokenHeldSupply += amount;
        _tokenBalances[toContract][toTokenId] += amount;

        emit XTransfer(from, type(uint256).max, toContract, toTokenId, amount);

        _afterTokenTransfer(from, toContract, toTokenId, amount);
    }

    function _transfer(
        address fromContract,
        uint256 fromTokenId,
        address to,
        uint256 amount
    ) internal virtual {
        require(
            fromContract != address(0),
            "SpellsCoin: transfer from the zero address"
        );
        require(to != address(0), "SpellsCoin: transfer to the zero address");

        _beforeTokenTransfer(fromContract, fromTokenId, to, amount);

        uint256 fromBalance = _tokenBalances[fromContract][fromTokenId];
        require(fromBalance >= amount, "SpellsCoin: transfer amount exceeds balance");
        unchecked {
            _tokenBalances[fromContract][fromTokenId] = fromBalance - amount;
            _totalTokenHeldSupply -= amount;
        }
        // do underlying token transfer
        _transfer(address(this), to, amount);

        emit XTransfer(
            fromContract,
            fromTokenId,
            to,
            type(uint256).max,
            amount
        );

        _afterTokenTransfer(fromContract, fromTokenId, to, amount);
    }

    function _transfer(
        address fromContract,
        uint256 fromTokenId,
        address toContract,
        uint256 toTokenId,
        uint256 amount
    ) internal virtual {
        require(
            fromContract != address(0),
            "SpellsCoin: transfer from the zero address"
        );
        require(toContract != address(0), "SpellsCoin: transfer to the zero address");
        _beforeTokenTransfer(
            fromContract,
            fromTokenId,
            toContract,
            toTokenId,
            amount
        );
        uint256 fromBalance = _tokenBalances[fromContract][fromTokenId];
        require(fromBalance >= amount, "SpellsCoin: transfer amount exceeds balance");
        unchecked {
            _tokenBalances[fromContract][fromTokenId] = fromBalance - amount;
        }
        _tokenBalances[toContract][toTokenId] += amount;

        emit XTransfer(
            fromContract,
            fromTokenId,
            toContract,
            toTokenId,
            amount
        );
        _afterTokenTransfer(
            fromContract,
            fromTokenId,
            toContract,
            toTokenId,
            amount
        );
    }
    
    function _transfer(
        DynamicAddress memory from,
        DynamicAddress memory to,
        uint256 amount
    ) internal virtual {
        require(from._address != address(0), "ERC20X: transfer from the zero address");
        require(to._address != address(0), "ERC20X: transfer to the zero address");
         if(from.isToken()){
            if(to.isToken()){
                _transfer(from._address, from._tokenId, to._address, to._tokenId, amount);
            } else {
                _transfer(from._address, from._tokenId, to._address, amount);
            }
        } else if(to.isToken()){
            _transfer(from._address, to._address, to._tokenId, amount);
        } else {
            _transfer(from._address, to._address, amount);
        }
    }

    function _mint(
        address _contract,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {
        require(_contract != address(0), "SpellsCoin: mint to the zero address");
        _beforeTokenTransfer(address(0), _contract, tokenId, amount);

        _tokenBalances[_contract][tokenId] += amount;
        _totalTokenHeldSupply += amount;
    
        // mint token to self in ERC20 standard contract
        _mint(address(this), amount);
        emit XTransfer(
            address(0),
            type(uint256).max,
            _contract,
            tokenId,
            amount
        );

        _afterTokenTransfer(address(0), _contract, tokenId, amount);
    }

    function increaseAllowance(
        address _contract,
        uint256 tokenId,
        address spender,
        uint256 addedValue
    ) public virtual override(IERC20X) returns (bool) {
        address owner = _ownerOf(_contract, tokenId);
        require(
            msg.sender == owner,
            "SpellsCoin: allowance change not initiated by token owner"
        );
        _approve(
            _contract,
            tokenId,
            spender,
            allowance(owner, _contract, tokenId, spender) + addedValue
        );
        return true;
    }

    function decreaseAllowance(
        address _contract,
        uint256 tokenId,
        address spender,
        uint256 subtractedValue
    ) public virtual override(IERC20X) returns (bool) {
        address owner = _ownerOf(_contract, tokenId);
        require(
            msg.sender == owner,
            "SpellsCoin: allowance change not initiated by token owner"
        );
        uint256 currentAllowance = allowance(
            owner,
            _contract,
            tokenId,
            spender
        );
        require(
            currentAllowance >= subtractedValue,
            "SpellsCoin: decreased allowance below zero"
        );
        unchecked {
            _approve(
                _contract,
                tokenId,
                spender,
                currentAllowance - subtractedValue
            );
        }
        return true;
    }

    function allowance(
        address _contract,
        uint256 tokenId,
        address spender
    ) public view virtual override(IERC20X) returns (uint256) {
        return
            _tokenAllowances[_ownerOf(_contract, tokenId)][_contract][tokenId][
                spender
            ];
    }

    function allowance(
        address tokenOwner,
        address _contract,
        uint256 tokenId,
        address spender
    ) public view virtual override(IERC20X) returns (uint256) {
        return _tokenAllowances[tokenOwner][_contract][tokenId][spender];
    }

    function approve(
        address _contract,
        uint256 tokenId,
        address spender,
        uint256 amount
    ) public virtual override(IERC20X) returns (bool) {
        address owner = _ownerOf(_contract, tokenId);
        require(
            msg.sender == owner,
            "SpellsCoin: approve not initiated by token owner"
        );
        _approve(_contract, tokenId, spender, amount);
        return true;
    }

    function _approve(
        address _contract,
        uint256 tokenId,
        address spender,
        uint256 amount
    ) internal virtual {
        require(_contract != address(0), "SpellsCoin: approve from the zero address");
        require(spender != address(0), "SpellsCoin: approve to the zero address");
        _tokenAllowances[msg.sender][_contract][tokenId][spender] = amount;
        emit XApproval(_contract, tokenId, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _spendAllowance(
        address _contract,
        uint256 tokenId,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(_contract, tokenId, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "SpellsCoin: insufficient allowance");
            unchecked {
                _approve(
                    _contract,
                    tokenId,
                    spender,
                    currentAllowance - amount
                );
            }
        }
    }

    function _beforeTokenTransfer(
        address fromContract,
        uint256 fromTokenId,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address fromContract,
        uint256 fromTokenId,
        address to,
        uint256 amount
    ) internal virtual {}

    function _beforeTokenTransfer(
        address from,
        address toContract,
        uint256 toTokenId,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address toContract,
        uint256 toTokenId,
        uint256 amount
    ) internal virtual {}

    function _beforeTokenTransfer(
        address fromContract,
        uint256 fromTokenId,
        address toContract,
        uint256 toTokenId,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address fromContract,
        uint256 fromTokenId,
        address toContract,
        uint256 toTokenId,
        uint256 amount
    ) internal virtual {}
    
    function signedTransferFrom(
        DynamicAddress calldata from,
        DynamicAddress calldata to,
        uint256 amount,
        uint256 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override(IERC20X) {
        require(
            from._address != address(0),
            "SpellsCoin: transfer from the zero address"
        );
        require(
            to._address != address(0),
            "SpellsCoin: transfer to the zero address"
        );
        address signer = from._address;
        if (from._address.isContract()){
            if(from._tokenId > 0 || from._useZeroToken){
                signer = _ownerOf(from._address, from._tokenId);
                require(_nonce == _nonces[from._address][from._tokenId], "SpellsCoin: invalid nonce");
                ++_nonces[from._address][from._tokenId];
            } else {
                signer = _ownerOf(from._address);
                require(_nonce == _addressNonces[signer], "SpellsCoin: invalid nonce");
                ++_addressNonces[signer];
            }
            require(signer != address(0), "SpellsCoin: transfer from the zero address");
        } else {
            require(_nonce == _addressNonces[signer], "SpellsCoin: invalid nonce");
            ++_addressNonces[signer];
        }
        require(
            ECDSA.isValidAccessMessage(
                signer,
                keccak256(
                    abi.encodePacked(
                        msg.sender, // single-caller permission
                        from._address,
                        from._tokenId,
                        from._useZeroToken,
                        to._address,
                        to._tokenId,
                        to._useZeroToken,
                        amount,
                        _nonce
                    )
                ),
                _v,
                _r,
                _s
            ),
            "ERC20X: invalid signature"
        );
        
        _transfer(from, to, amount);
    }

    function _ownerOf(address _contract, uint256 tokenId)
        internal
        view
        returns (address)
    {
        return _IERC721(_contract).ownerOf(tokenId);
    }

    function _ownerOf(address _contract) internal view returns (address) {
        require(_contract != address(0), "SpellsCoin: zero address");
        (bool success, bytes memory returnData) = _contract.staticcall(
            abi.encodeWithSignature("owner()")
        );
        require(success, "SpellsCoin: could not assess owner");
        address owner = abi.decode(returnData, (address));
        return owner;
    }

    // Convenience method to allow withdrawal from contracts that do not support ERC-20.
    function withdrawFromContract(address _contract, uint256 amount)
        public
        nonReentrant
    {
        require(
            _contract != address(0),
            "SpellsCoin: transfer from the zero address"
        );
        require(msg.sender == _ownerOf(_contract), "SpellsCoin: invalid withdrawal");
        _transfer(_contract, msg.sender, amount);
    }
}