# Wavy Event Logging Architecture

Wavy instruments user actions directly tying back to business objectives ranging from swipe engagement to conversion (calling/contacting sellers). Events wait in an offline queue (Hive powered) if the app experiences poor connectivity.

## Core Events

| Event Type          | Triggered When                   | Key Metadata Needed                               |
|---------------------|----------------------------------|---------------------------------------------------|
| `swipe_event`       | Feed deck swipes                 | `direction`: `pass` (left), `save` (right)        |
| `interest_event`    | "I Want This" clicked            | `item_id`, `seller_id`                            |
| `call_event`        | User clicks "Call" phone wrapper | `item_id`, `seller_id`                            |
| `mark_sold`         | Seller manually flags as sold    | `item_id`, `seller_id`                            |
| `publish_event`     | User/Seller pushes a new item    | `category`, `price`, `condition`                  |

*All events share common metadata fields like `userId`, `timestamp` (UTC), and `appVersion`.*
