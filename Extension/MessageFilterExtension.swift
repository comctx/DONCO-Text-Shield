import Foundation
import IdentityLookup

final class MessageFilterExtension: ILMessageFilterExtension, ILMessageFilterQueryHandling {
    func handle(_ queryRequest: ILMessageFilterQueryRequest,
                context: ILMessageFilterExtensionContext,
                completion: @escaping (ILMessageFilterQueryResponse) -> Void) {
        let settings = SharedFilterSettings.load()
        let result = MessageClassifier.classify(queryRequest.messageBody ?? "", settings: settings)
        let response = ILMessageFilterQueryResponse()
        switch result.decision {
        case .junk: response.action = .junk
        case .promotion: response.action = .promotion
        case .allow: response.action = .allow
        }
        completion(response)
    }
}
