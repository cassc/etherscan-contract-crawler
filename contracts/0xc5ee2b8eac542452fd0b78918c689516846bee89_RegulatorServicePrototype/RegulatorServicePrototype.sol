/**
 *Submitted for verification at Etherscan.io on 2021-01-14
*/

// SPDX-License-Identifier: MIT
/**
   Copyright (c) 2019-2021 Digital Asset Exchange Limited
   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:
   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.
   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.
*/

pragma solidity 0.7.5;





/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// AddrSet is an address set based on http://solidity.readthedocs.io/en/develop/contracts.html#libraries
library AddrSet {
    // We define a new struct datatype that will be used to
    // hold its data in the calling contract.
    struct Data {
        mapping(address => bool) flags;
    }

    // Note that the first parameter is of type "storage
    // reference" and thus only its storage address and not
    // its contents is passed as part of the call.  This is a
    // special feature of library functions.  It is idiomatic
    // to call the first parameter `self`, if the function can
    // be seen as a method of that object.
    function insert(Data storage self, address value) internal returns (bool) {
        if (self.flags[value]) {
            return false; // already there
        }
        self.flags[value] = true;
        return true;
    }

    function remove(Data storage self, address value) internal returns (bool) {
        if (!self.flags[value]) {
            return false; // not there
        }
        self.flags[value] = false;
        return true;
    }

    function contains(Data storage self, address value)
        internal
        view
        returns (bool)
    {
        return self.flags[value];
    }
}
/**
   Copyright (c) 2019-2021 Digital Asset Exchange Limited
   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:
   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.
   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.
*/


/**
 * @title BaseSecurityToken interface
 * @dev see https://github.com/ethereum/EIPs/pull/1462
 */
interface IBaseSecurityToken {
    function attachDocument(
        bytes32 _name,
        string calldata _uri,
        bytes32 _contentHash
    ) external;

    function lookupDocument(bytes32 _name)
        external
        view
        returns (string memory, bytes32);

    /**
     * @return byte status code (ESC): 0x11 for Allowed, for other please refer to ERC-1066.
     */
    function checkTransferAllowed(
        address from,
        address to,
        uint256 value
    ) external view returns (byte);

    /**
     * @return byte status code (ESC): 0x11 for Allowed, for other please refer to ERC-1066.
     */
    function checkTransferFromAllowed(
        address from,
        address to,
        uint256 value
    ) external view returns (byte);

    /**
     * @return byte status code (ESC): 0x11 for Allowed, for other please refer to ERC-1066.
     */
    function checkMintAllowed(address to, uint256 value)
        external
        view
        returns (byte);

    /**
     * @return byte status code (ESC): 0x11 for Allowed, for other please refer to ERC-1066.
     */
    function checkBurnAllowed(address from, uint256 value)
        external
        view
        returns (byte);
}
/**
   Copyright (c) 2017 Harbor Platform, Inc.
   Licensed under the Apache License, Version 2.0 (the “License”);
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at
   http://www.apache.org/licenses/LICENSE-2.0
   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an “AS IS” BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/


interface IRegulatorService {
    function check(
        address _token,
        address _spender,
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (byte);
}

contract RegulatorServicePrototype is IRegulatorService, Ownable {
    // Status corresponding to the state of approvement:
    // * Unknown when an address has not been processed yet;
    // * Approved when an address has been approved by contract owner or 3rd party KYC provider;
    // * Suspended means a temporary or permanent suspension of all operations, any KYC providers may
    // set this status when account needs to be re-verified due to legal events or blocked because of fraud.
    enum Status {
        Unknown,
        Approved,
        Suspended
    }

    // Events emitted by this contract
    event ProviderAdded(address indexed addr);
    event ProviderRemoved(address indexed addr);
    event AddrApproved(address indexed addr, address indexed by);
    event AddrSuspended(address indexed addr, address indexed by);

    // Uses status codes from ERC-1066
    byte private constant DISALLOWED = 0x10;
    byte private constant ALLOWED = 0x11;

    // Contract state
    AddrSet.Data private kycProviders;
    mapping(address => Status) public kycStatus;

    constructor() Ownable() {
    }

    // registerProvider adds a new 3rd-party provider that is authorized to perform KYC.
    function registerProvider(address addr) public onlyOwner {
        require(AddrSet.insert(kycProviders, addr), "already registered");
        emit ProviderAdded(addr);
    }

    // removeProvider removes a 3rd-party provider that was authorized to perform KYC.
    function removeProvider(address addr) public onlyOwner {
        require(AddrSet.remove(kycProviders, addr), "not registered");
        emit ProviderRemoved(addr);
    }

    // isProvider returns true if the given address was authorized to perform KYC.
    function isProvider(address addr) public view returns (bool) {
        return addr == owner() || AddrSet.contains(kycProviders, addr);
    }

    // getStatus returns the KYC status for a given address.
    function getStatus(address addr) public view returns (Status) {
        return kycStatus[addr];
    }

    // approveAddr sets the address status to Approved, see Status for details.
    // Can be invoked by owner or authorized KYC providers only.
    function approveAddr(address addr) public onlyAuthorized {
        Status status = kycStatus[addr];
        require(status != Status.Approved, "already approved");
        kycStatus[addr] = Status.Approved;
        emit AddrApproved(addr, msg.sender);
    }

    // suspendAddr sets the address status to Suspended, see Status for details.
    // Can be invoked by owner or authorized KYC providers only.
    function suspendAddr(address addr) public onlyAuthorized {
        Status status = kycStatus[addr];
        require(status != Status.Suspended, "already suspended");
        kycStatus[addr] = Status.Suspended;
        emit AddrSuspended(addr, msg.sender);
    }

    function check(
        address _token,
        address _spender,
        address _from,
        address _to,
        uint256 /*_amount*/
    )
        external
        override
        view
        returns (byte)
    {
        require(_token != address(0), "token address is empty");
        require(_spender != address(0), "spender address is empty");
        require(_from != address(0) || _to != address(0), "undefined account addresses");

        if (getStatus(_spender) != Status.Approved) {
            return DISALLOWED;
        }

        if (_from != address(0)) {
            Status status = getStatus(_from);
            if (_to == address(0)) {
                //tokens can be burned only when the owner's address is suspended
                //this also means that _spender and _from addresses are different
                if (status != Status.Suspended) {
                    return DISALLOWED;
                }

                return ALLOWED;
            }

            if (status != Status.Approved) {
                return DISALLOWED;
            }
        }

        if (getStatus(_to) != Status.Approved) {
            return DISALLOWED;
        }

        return ALLOWED;
    }

    // onlyAuthorized modifier restricts write access to contract owner and authorized KYC providers.
    modifier onlyAuthorized() {
        require(
            msg.sender == owner() || AddrSet.contains(kycProviders, msg.sender),
            "onlyAuthorized can do"
        );
        _;
    }
}