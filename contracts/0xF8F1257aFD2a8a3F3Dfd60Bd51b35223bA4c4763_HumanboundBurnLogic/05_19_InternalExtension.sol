//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Extension.sol";
import "../utils/Internal.sol";
import "../errors/Errors.sol";

/**
 *  ______  __  __  ______  ______  __   __  _____   ______  ______  __      ______    
 * /\  ___\/\_\_\_\/\__  _\/\  ___\/\ "-.\ \/\  __-./\  __ \/\  == \/\ \    /\  ___\
 * \ \  __\\/_/\_\/\/_/\ \/\ \  __\\ \ \-.  \ \ \/\ \ \  __ \ \  __<\ \ \___\ \  __\
 *  \ \_____\/\_\/\_\ \ \_\ \ \_____\ \_\\"\_\ \____-\ \_\ \_\ \_____\ \_____\ \_____\
 *   \/_____/\/_/\/_/  \/_/  \/_____/\/_/ \/_/\/____/ \/_/\/_/\/_____/\/_____/\/_____/
 *
 *  Base contract for Internal Extensions in the Extendable Framework
 *  
 *  Internal Extensions are used to house common functions that are used by other contract extensions.
 *  This is used to make internal functions usable across all your extensions without exposing it
 *  to the external world.
 *
 *  Define your custom Extension interface and implement it whilst inheriting this contract:
 *      contract YourExtension is IYourExtension, InternalExtension {...}
 *
 *  Then define your function and simply modify it in the following way:
 *      contract YourExtension is IYourExtension, InternalExtension {
 *          function _someFunc() public _internal {}
 *      }
 *   
 *  Notice that your internal function carries both the `public` visibility modifier and the `_internal` 
 *  modifier. This is because cross-extension calls are resolved as external calls and `public` allows
 *  your other extensions to call them whilst `_internal` restricts callers to only extensions of the
 *  same contract.
 *
 *  Note:
 *  Use underscores `_` as internal function prefixes as general naming convention.
 */
abstract contract InternalExtension is Internal, Extension {}