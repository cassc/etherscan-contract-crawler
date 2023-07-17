// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;
import "./HasRegistration.sol";
import "./IHandlerCallback.sol";

contract HasCallbacksUpgradable is HasRegistration {

    bool allowCallbacks;
    
    event CallbackExecuted(address _from, address _to, address target, uint256 tokenId, bytes4 targetFunction, IHandlerCallback.CallbackType _type, bytes returnData);
    event CallbackReverted(address _from, address _to, address target, uint256 tokenId, bytes4 targetFunction, IHandlerCallback.CallbackType _type);
    event CallbackFailed(address _from, address _to, address target, uint256 tokenId, bytes4 targetFunction, IHandlerCallback.CallbackType _type);
    
    mapping(address => mapping(uint256 => mapping(IHandlerCallback.CallbackType => IHandlerCallback.Callback[]))) public registeredCallbacks;
    mapping(address => mapping(IHandlerCallback.CallbackType => IHandlerCallback.Callback[])) public registeredWildcardCallbacks;    

    modifier isOwnerOrCallbackRegistrant(address _contract, address target, uint256 tokenId, IHandlerCallback.CallbackType _type, uint256 index) {
        bool registrant = false;
        if (hasTokenIdCallback(_contract, target, tokenId, _type)) {
            registrant = registeredCallbacks[_contract][tokenId][_type][index].registrant == _msgSender();
        } else if(hasWildcardCallback(_contract, target, _type)) {
           registrant = registeredWildcardCallbacks[_contract][_type][index].registrant == _msgSender();
        }        
        require(_msgSender() == owner() || registrant, "Not owner or Callback registrant");
        _;
    }

    function executeCallbacks(address _from, address _to, uint256 tokenId, IHandlerCallback.CallbackType _type) public isRegisteredContract(_msgSender()) {
        if (allowCallbacks) {
            IHandlerCallback.Callback[] memory callbacks = registeredCallbacks[_msgSender()][tokenId][_type];
            if (callbacks.length > 0) executeCallbackLoop(callbacks, _from, _to, tokenId, _type);
            IHandlerCallback.Callback[] memory wildCardCallbacks = registeredWildcardCallbacks[_msgSender()][_type];
            if (wildCardCallbacks.length > 0) executeCallbackLoop(wildCardCallbacks, _from, _to, tokenId, _type);
        }
    }

    function executeCallbacksInternal(address _nftAddress, address _from, address _to, uint256 tokenId, IHandlerCallback.CallbackType _type) internal isRegisteredContract(_nftAddress) {
         if (allowCallbacks) {
            IHandlerCallback.Callback[] memory callbacks = registeredCallbacks[_nftAddress][tokenId][_type];
            if (callbacks.length > 0) executeCallbackLoop(callbacks, _from, _to, tokenId, _type);
            IHandlerCallback.Callback[] memory wildCardCallbacks = registeredWildcardCallbacks[_nftAddress][_type];
            if (wildCardCallbacks.length > 0) executeCallbackLoop(wildCardCallbacks, _from, _to, tokenId, _type);
         }
    }

    function executeCallbackLoop(IHandlerCallback.Callback[] memory callbacks, address _from, address _to, uint256 tokenId, IHandlerCallback.CallbackType _type) internal {
        bool canRevert = false;  
        for (uint256 i = 0; i < callbacks.length; ++i) {            
            IHandlerCallback.Callback memory cb = callbacks[i];    
            canRevert = cb.canRevert;
            if (cb.target != address(0)){
                (bool success, bytes memory returnData) =
                    address(cb.target).call(
                        abi.encodePacked(
                            cb.targetFunction,
                            abi.encode(_from),
                            abi.encode(_to),
                            abi.encode(tokenId)
                        )
                    );
                if (success) {
                    emit CallbackExecuted(_from, _to, cb.target, tokenId, cb.targetFunction, _type, returnData);
                } else if (canRevert) {
                    emit CallbackReverted(_from, _to, cb.target, tokenId, cb.targetFunction, _type);
                    revert("Callback Reverted");
                } else {
                    emit CallbackFailed(_from, _to, cb.target, tokenId, cb.targetFunction, _type);
                }
            }
        }
    }

    function toggleAllowCallbacks() public onlyOwner {
        allowCallbacks = !allowCallbacks;
    }

    function registerCallback(address _contract, address target, uint256 tokenId, IHandlerCallback.CallbackType _type, bytes4 _function, bool allowRevert) isRegisteredContract(_contract) onlyOwner public {
        registeredCallbacks[_contract][tokenId][_type].push(IHandlerCallback.Callback(_contract, _msgSender(), target, _function, allowRevert ));
    }

    function registerWildcardCallback(address _contract, address target, IHandlerCallback.CallbackType _type, bytes4 _function, bool allowRevert) isRegisteredContract(_contract) onlyOwner public {
        registeredWildcardCallbacks[_contract][_type].push(IHandlerCallback.Callback(_contract, _msgSender(), target, _function, allowRevert ));
    }

    function hasCallback(address _contract, address target, uint256 tokenId, IHandlerCallback.CallbackType _type) public view returns (bool ) {
        bool found = hasTokenIdCallback(_contract, target, tokenId, _type);
        if (found) return true;
        return hasWildcardCallback(_contract, target, _type);
    }

    function hasTokenIdCallback(address _contract, address target, uint256 tokenId, IHandlerCallback.CallbackType _type) internal view returns(bool) {
        bool found = false;
        IHandlerCallback.Callback[] memory callbacks = registeredCallbacks[_contract][tokenId][_type];
        for (uint256 i = 0; i < callbacks.length; ++i) {
            if (callbacks[i].target == target) {
                found = true;
            }
        }
        return found;
    }

    function hasWildcardCallback(address _contract, address target, IHandlerCallback.CallbackType _type) internal view returns(bool) {
        bool found = false;
        IHandlerCallback.Callback[] memory callbacks = registeredWildcardCallbacks[_contract][_type];
        for (uint256 i = 0; i < callbacks.length; ++i) {
            if (callbacks[i].target == target) {
                found = true;
            }
        }
        return found;
    }

    function unregisterCallback(address _contract, address target, uint256 tokenId, IHandlerCallback.CallbackType _type, uint256 index) public isOwnerOrCallbackRegistrant(_contract, target, tokenId, _type, index){
        if (hasTokenIdCallback(_contract, target, tokenId, _type)) {
            IHandlerCallback.Callback[] storage arr = registeredCallbacks[_contract][tokenId][_type];
            arr[index] = arr[arr.length - 1];
            arr.pop();
            // delete registeredCallbacks[_contract][tokenId][_type][index];
        }
        else if(hasWildcardCallback(_contract, target, _type)) {
            IHandlerCallback.Callback[] storage arr = registeredWildcardCallbacks[_contract][_type];
            arr[index] = arr[arr.length - 1];
            arr.pop();
            // delete registeredWildcardCallbacks[_contract][_type][index];
        }
    }
}