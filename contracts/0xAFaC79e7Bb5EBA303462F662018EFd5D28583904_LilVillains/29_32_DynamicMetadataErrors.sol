// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
// Invalid operation. Needed _defaultImagePath to be set
error DefaultImagePathRequired();
// Invalid operation. Can't set imagePath to token without baseAttributes'
// @param tokenId sent tokenId.
// @param imagePath sent imagePath.
error CannotSetImageWithoutBaseAttributes(uint256 tokenId, string imagePath);
// Invalid operation. Token already has base attributes set.
// @param tokenId sent tokenId.
error AlreadyHaveBaseAttributes(uint256 tokenId);
// Invalid operation. Method is not supported yet.
// @param method method that wants to be executed.
error MethodNotSupported(string method);